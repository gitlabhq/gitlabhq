<script>
import {
  GlModal,
  GlSearchBoxByType,
  GlButton,
  GlIcon,
  GlCollapse,
  GlEmptyState,
  GlLink,
  GlLoadingIcon,
} from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { HTTP_STATUS_TOO_MANY_REQUESTS } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  onboardingFeatureLibrarySearchPath,
  onboardingFeatureLibraryAiSearchPath,
} from '~/lib/utils/path_helpers/feature_library';
import { InternalEvents } from '~/tracking';
import {
  EVENT_OPEN_FEATURE_LIBRARY_MODAL,
  EVENT_SEARCH_FEATURES_IN_FEATURE_LIBRARY_MODAL,
  EVENT_PIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
  EVENT_UNPIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
  EVENT_NAVIGATE_TO_FEATURE_FROM_FEATURE_LIBRARY_MODAL,
  EVENT_SEARCH_WITH_GEMINI_IN_FEATURE_LIBRARY_MODAL,
} from '../../tracking_constants';
import { PANEL_TYPES } from '../../constants';
import ScrollScrim from '../scroll_scrim.vue';
import { FEEDBACK_ISSUE_URL, MODAL_ID, ITEMS_PER_RENDER_FRAME } from './constants';
import FeatureLibraryItem from './feature_library_item.vue';

const SETTINGS_MENU_ID = 'settings_menu';
// Items flagged as hidden in the super sidebar (e.g. duplicate "Work items"
// entries) must be excluded here too, mirroring menu_section.vue's filter.
const HIDDEN_NAV_ITEM_CLASS = 'js-super-sidebar-nav-item-hidden';
const trackingMixin = InternalEvents.mixin();
const MIN_SEARCH_QUERY_LENGTH = 2;

export default {
  name: 'FeatureLibraryModal',
  components: {
    GlModal,
    GlSearchBoxByType,
    GlButton,
    GlIcon,
    GlCollapse,
    GlEmptyState,
    GlLink,
    GlLoadingIcon,
    ScrollScrim,
    FeatureLibraryItem,
  },
  mixins: [trackingMixin],
  modalId: MODAL_ID,
  DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
  FEEDBACK_ISSUE_URL,
  inject: {
    panelType: { default: '' },
    resourceId: { default: null },
    aiSearchAvailable: { default: false },
  },
  props: {
    supportsPins: {
      type: Boolean,
      required: false,
      default: false,
    },
    sections: {
      type: Array,
      required: false,
      default: () => [],
    },
    currentPinnedIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    showFeedbackLink: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['pin-toggle'],
  data() {
    return {
      searchQuery: '',
      collapsedSectionIds: [],
      searchResultIds: [],
      isSearching: false,
      latestQuery: null,
      renderLimit: ITEMS_PER_RENDER_FRAME,
      revealFrameId: null,
      geminiResultIds: [],
      isGeminiSearching: false,
      geminiSearched: false,
      geminiHidden: false,
      geminiErrorMessage: null,
    };
  },
  computed: {
    trimmedQuery() {
      return this.searchQuery.trim();
    },
    hasSearchableQuery() {
      return this.trimmedQuery.length >= MIN_SEARCH_QUERY_LENGTH;
    },
    searchPlaceholder() {
      switch (this.panelType) {
        case PANEL_TYPES.PROJECT:
          return s__('FeatureLibrary|Search features in this project');
        case PANEL_TYPES.GROUP:
          return s__('FeatureLibrary|Search features in this group');
        default:
          return s__('FeatureLibrary|Search GitLab features');
      }
    },
    catalogSections() {
      return this.sections
        .map((section) => ({
          ...section,
          items: (section.items || []).filter(
            (item) => !item.link_classes?.includes(HIDDEN_NAV_ITEM_CLASS),
          ),
        }))
        .filter((section) => {
          // The settings menu currently remains in the super sidebar and should not appear within
          // the modal, nor have its items pinnable.
          if (section.id === SETTINGS_MENU_ID) {
            return false;
          }
          return section.items.length > 0;
        });
    },
    catalog() {
      return this.catalogSections.flatMap((section) =>
        section.items.map((item) => ({
          id: item.id,
          title: item.title,
          description: item.description,
          icon: item.library_icon || item.icon,
          tier: item.tier,
          category: section.id,
          link: item.link,
        })),
      );
    },
    catalogById() {
      return Object.fromEntries(this.catalog.map((item) => [item.id, item]));
    },
    filteredItems() {
      const q = this.trimmedQuery.toLowerCase();

      if (!q) return this.catalog;

      const textMatches = (text = '') => text.toLowerCase().includes(q);

      // Synonym matches from endpoint come first: backend-ranked (exact -> prefix -> contains).
      const synonymMatches = this.searchResultIds
        .map((id) => this.catalogById[id])
        .filter((item) => item);

      // Direct title/description matches follow, excluding any already surfaced as synonyms.
      const synonymIds = new Set(synonymMatches.map((item) => item.id));
      const directMatches = this.catalog.filter(
        (item) =>
          !synonymIds.has(item.id) && (textMatches(item.title) || textMatches(item.description)),
      );

      return [...synonymMatches, ...directMatches];
    },
    // Sections with their items, honoring the progressive reveal limit.
    // Used when not searching, so each category renders under its own heading.
    //
    // Every section heading is always included so the section list is stable
    // regardless of the reveal budget; only the items within each section are
    // limited, and the budget is distributed across sections in order.
    groupedSections() {
      let remaining = this.renderLimit;

      return this.catalogSections.map((section) => {
        const items = section.items
          .slice(0, Math.max(remaining, 0))
          .map((item) => this.catalogById[item.id])
          .filter(Boolean);

        remaining -= items.length;

        return { id: section.id, title: section.title, items };
      });
    },
    showEmptyState() {
      return (
        !this.isSearching &&
        !this.isGeminiSearching &&
        this.hasSearchableQuery &&
        this.filteredItems.length === 0 &&
        !this.showGeminiEmptyState
      );
    },
    geminiItems() {
      if (!this.geminiResultIds.length) return [];

      const shownIds = new Set(this.filteredItems.map((item) => item.id));

      return this.geminiResultIds
        .map((id) => this.catalogById[id])
        .filter((item) => item && !shownIds.has(item.id));
    },
    showGeminiSection() {
      return (
        (this.isGeminiSearching || this.geminiSearched || Boolean(this.geminiErrorMessage)) &&
        !this.geminiHidden
      );
    },
    showGeminiHeader() {
      return (this.geminiSearched || Boolean(this.geminiErrorMessage)) && !this.geminiHidden;
    },
    showGeminiEmptyState() {
      return (
        this.showGeminiSection &&
        !this.isGeminiSearching &&
        !this.geminiErrorMessage &&
        this.geminiItems.length === 0
      );
    },
    showGeminiButton() {
      return (
        this.aiSearchAvailable &&
        this.resourceId &&
        !this.isSearching &&
        this.hasSearchableQuery &&
        (!this.geminiSearched || this.geminiHidden) &&
        !this.isGeminiSearching
      );
    },
    showFooter() {
      return this.showFeedbackLink || this.showGeminiButton;
    },
    emptyStateTitle() {
      return s__('FeatureLibrary|No features match your search');
    },
  },
  beforeUnmount() {
    this.cancelReveal();
  },
  methods: {
    isPinned(itemId) {
      return this.currentPinnedIds.includes(itemId);
    },
    isSectionExpanded(sectionId) {
      return !this.collapsedSectionIds.includes(sectionId);
    },
    toggleSection(sectionId) {
      if (this.isSectionExpanded(sectionId)) {
        this.collapsedSectionIds.push(sectionId);
      } else {
        this.collapsedSectionIds = this.collapsedSectionIds.filter((id) => id !== sectionId);
      }
    },
    onShown() {
      this.$refs.searchBox?.focusInput();
      this.revealRemainingItems();
      this.trackEvent(EVENT_OPEN_FEATURE_LIBRARY_MODAL);
    },
    onSearchEnter() {
      if (!this.trimmedQuery || this.isSearching) return;

      const [firstItem] = this.filteredItems;
      if (!firstItem?.link) return;

      this.onNavigate(firstItem.id);
      this.$refs.modal.hide();
      visitUrl(firstItem.link);
    },
    revealRemainingItems() {
      if (this.renderLimit >= this.catalog.length) return;
      this.revealFrameId = window.requestAnimationFrame(() => {
        this.renderLimit += ITEMS_PER_RENDER_FRAME;
        this.revealRemainingItems();
      });
    },
    cancelReveal() {
      if (this.revealFrameId) {
        window.cancelAnimationFrame(this.revealFrameId);
        this.revealFrameId = null;
      }
    },
    resetSearchState() {
      this.isSearching = false;
      this.latestQuery = null;
      this.searchResultIds = [];
    },
    resetGeminiState() {
      this.geminiResultIds = [];
      this.isGeminiSearching = false;
      this.geminiSearched = false;
      this.geminiHidden = false;
      this.geminiErrorMessage = null;
    },
    onSearchInput(value) {
      this.searchQuery = value;
      const query = value.trim();
      this.resetGeminiState();

      if (query) {
        this.fetchResults(query);
        this.trackEvent(EVENT_SEARCH_FEATURES_IN_FEATURE_LIBRARY_MODAL);
      } else {
        this.resetSearchState();
      }
    },
    onPinToggle(itemId, nextState, title) {
      this.$emit('pin-toggle', itemId, nextState, title);
      const event = nextState
        ? EVENT_PIN_ITEM_IN_FEATURE_LIBRARY_MODAL
        : EVENT_UNPIN_ITEM_IN_FEATURE_LIBRARY_MODAL;
      this.trackEvent(event, { label: itemId });
    },
    onNavigate(itemId) {
      this.trackEvent(EVENT_NAVIGATE_TO_FEATURE_FROM_FEATURE_LIBRARY_MODAL, {
        label: itemId,
      });
    },
    onHidden() {
      this.resetSearchState();
      this.resetGeminiState();
      this.cancelReveal();
      this.searchQuery = '';
      this.collapsedSectionIds = [];
      this.renderLimit = ITEMS_PER_RENDER_FRAME;
    },
    fetchResults(query) {
      this.searchResultIds = [];

      if (query.length < MIN_SEARCH_QUERY_LENGTH) {
        this.isSearching = false;
        this.latestQuery = null;
        return;
      }

      this.latestQuery = query;
      this.isSearching = true;

      axios
        .get(onboardingFeatureLibrarySearchPath(), { params: { query, panel: this.panelType } })
        .then(({ data }) => {
          if (query !== this.latestQuery) return;
          this.searchResultIds = data.ids || [];
        })
        .catch((e) => {
          if (query !== this.latestQuery) return;
          if (e.response?.status !== HTTP_STATUS_TOO_MANY_REQUESTS) {
            Sentry.captureException(e, { tags: { feature_category: 'onboarding' } });
          }
          this.searchResultIds = [];
        })
        .finally(() => {
          if (query !== this.latestQuery) return;
          this.isSearching = false;
        });
    },
    async searchWithGemini() {
      if (!this.resourceId || !this.aiSearchAvailable) return;

      const query = this.trimmedQuery;
      this.trackEvent(EVENT_SEARCH_WITH_GEMINI_IN_FEATURE_LIBRARY_MODAL);
      this.geminiHidden = false;
      this.isGeminiSearching = true;
      this.geminiErrorMessage = null;

      try {
        const { data } = await axios.get(onboardingFeatureLibraryAiSearchPath(), {
          params: { query, panel: this.panelType, resource_id: this.resourceId },
        });
        if (query !== this.trimmedQuery) return;
        this.geminiResultIds = data.ids || [];
        this.geminiSearched = true;
      } catch (e) {
        if (query !== this.trimmedQuery) return;

        const status = e.response?.status;
        if (status === HTTP_STATUS_TOO_MANY_REQUESTS) {
          this.geminiErrorMessage =
            e.response?.data?.error ||
            s__('FeatureLibrary|You have reached the search limit. Try again later.');
        } else {
          // Includes 404: the button is gated on aiSearchAvailable, so this
          // shouldn't normally occur; if it does (e.g. a stale flag/trial state),
          // it's unexpected and worth reporting.
          Sentry.captureException(e, { tags: { feature_category: 'onboarding' } });
          this.geminiErrorMessage = s__(
            'FeatureLibrary|Something went wrong searching with Gemini. Try again.',
          );
        }
      } finally {
        if (query === this.trimmedQuery) {
          this.isGeminiSearching = false;
        }
      }
    },
    hideGeminiSection() {
      this.geminiHidden = true;
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="$options.modalId"
    :aria-label="s__('FeatureLibrary|GitLab features')"
    :hide-footer="!showFooter"
    modal-class="feature-library-modal"
    body-class="gl-flex gl-flex-col"
    size="lg"
    scrollable
    hide-header
    @shown="onShown"
    @hidden="onHidden"
  >
    <gl-search-box-by-type
      ref="searchBox"
      :value="searchQuery"
      :placeholder="searchPlaceholder"
      :debounce="$options.DEFAULT_DEBOUNCE_AND_THROTTLE_MS"
      class="gl-mb-4 gl-mt-3"
      @input="onSearchInput"
      @keydown.enter="onSearchEnter"
    />
    <scroll-scrim
      data-testid="feature-library-scroll-area"
      class="feature-library-scroll-area feature-library-scroll-bleed gl-min-h-0 gl-grow"
    >
      <div class="feature-library-scroll-inset">
        <!-- Search results: a single flat, ranked grid. -->
        <ul
          v-if="trimmedQuery && !isSearching && filteredItems.length > 0"
          data-testid="feature-library-grid"
          class="gl-grid gl-list-none gl-grid-cols-1 gl-gap-3 gl-p-0 sm:gl-grid-cols-2 md:gl-grid-cols-3"
        >
          <feature-library-item
            v-for="item in filteredItems"
            :key="item.id"
            :supports-pins="supportsPins"
            :item="item"
            :pinned="isPinned(item.id)"
            @pin-toggle="onPinToggle"
            @navigate="onNavigate"
          />
        </ul>
        <!-- Browsing: features grouped by category, each in a collapsible section. -->
        <template v-else-if="!trimmedQuery">
          <section
            v-for="section in groupedSections"
            :key="section.id"
            data-testid="feature-library-section"
            class="gl-mb-3"
          >
            <h3 class="gl-m-0">
              <gl-button
                category="tertiary"
                size="small"
                block
                button-text-classes="gl-flex gl-w-full gl-items-center gl-gap-2 gl-text-base gl-font-semibold gl-text-subtle"
                :aria-expanded="isSectionExpanded(section.id) ? 'true' : 'false'"
                :aria-controls="`feature-library-section-${section.id}`"
                data-testid="feature-library-section-toggle"
                @click="toggleSection(section.id)"
              >
                <span class="gl-grow gl-text-left">{{ section.title }}</span>
                <gl-icon :name="isSectionExpanded(section.id) ? 'chevron-down' : 'chevron-right'" />
              </gl-button>
            </h3>
            <gl-collapse
              :id="`feature-library-section-${section.id}`"
              :visible="isSectionExpanded(section.id)"
            >
              <ul
                data-testid="feature-library-section-grid"
                class="gl-mt-2 gl-grid gl-list-none gl-grid-cols-1 gl-gap-3 gl-p-0 sm:gl-grid-cols-2 md:gl-grid-cols-3"
              >
                <feature-library-item
                  v-for="item in section.items"
                  :key="item.id"
                  :supports-pins="supportsPins"
                  :item="item"
                  :pinned="isPinned(item.id)"
                  @pin-toggle="onPinToggle"
                  @navigate="onNavigate"
                />
              </ul>
            </gl-collapse>
          </section>
        </template>
        <gl-loading-icon
          v-if="isSearching"
          size="sm"
          class="gl-mt-3"
          data-testid="search-loading"
        />
        <gl-empty-state
          v-if="showEmptyState"
          :title="emptyStateTitle"
          :description="s__('FeatureLibrary|Try a different search term.')"
        />
        <template v-if="showGeminiSection">
          <div
            :class="[
              'gl-p-4',
              'gl-pt-3',
              { 'gl-border-t': !isGeminiSearching && !(showGeminiEmptyState && !showEmptyState) },
            ]"
          >
            <div v-if="showGeminiHeader" class="gl-flex gl-items-center gl-justify-between gl-py-2">
              <h3 class="gl-m-0 gl-text-base gl-font-bold">
                <gl-icon name="tanuki-ai" :size="16" class="gl-mr-2" />
                {{ s__('FeatureLibrary|Suggested by Gemini') }}
              </h3>
              <gl-button
                category="tertiary"
                size="small"
                data-testid="hide-gemini-section"
                @click="hideGeminiSection"
              >
                {{ s__('FeatureLibrary|Hide') }}
              </gl-button>
            </div>
            <div
              v-if="isGeminiSearching || geminiErrorMessage || showGeminiEmptyState"
              class="gl-flex gl-items-center gl-justify-center gl-gap-3 gl-py-5 gl-text-subtle"
            >
              <template v-if="isGeminiSearching">
                <gl-loading-icon size="sm" data-testid="gemini-loading" />
                <span>{{ s__('FeatureLibrary|Searching with Gemini …') }}</span>
              </template>
              <span v-else-if="geminiErrorMessage" data-testid="gemini-error">
                {{ geminiErrorMessage }}
              </span>
              <span v-else data-testid="gemini-empty-state">
                {{
                  s__(
                    "FeatureLibrary|Gemini couldn't find a matching feature. Try different keywords.",
                  )
                }}
              </span>
            </div>
            <ul
              v-if="geminiItems.length > 0"
              data-testid="gemini-results-grid"
              class="gl-grid gl-list-none gl-grid-cols-1 gl-gap-3 gl-p-0 sm:gl-grid-cols-2 md:gl-grid-cols-3"
            >
              <feature-library-item
                v-for="item in geminiItems"
                :key="item.id"
                :item="item"
                :pinned="isPinned(item.id)"
                @pin-toggle="onPinToggle"
                @navigate="onNavigate"
              />
            </ul>
            <p v-if="geminiItems.length > 0" class="gl-mb-0 gl-text-subtle">
              {{ s__('FeatureLibrary|Recommended based on your search') }}
            </p>
          </div>
        </template>
      </div>
    </scroll-scrim>
    <template #modal-footer>
      <div class="gl-m-0 gl-flex gl-w-full gl-flex-col gl-gap-4">
        <gl-button
          v-if="showGeminiButton"
          class="feature-library-gemini-button"
          block
          data-testid="search-with-gemini-button"
          :button-text-classes="['gl-flex', 'gl-justify-between', 'gl-w-full']"
          @click="searchWithGemini"
        >
          <span class="gl-my-3">
            {{ s__("FeatureLibrary|Can't find what you're looking for? Search with AI") }}
          </span>
          <span class="gl-my-3 gl-text-sm">
            <gl-icon name="tanuki-ai" :size="16" />
            <span>{{ s__('FeatureLibrary|Powered by Gemini') }}</span>
          </span>
        </gl-button>

        <div v-if="showFeedbackLink" class="gl-text-center gl-text-sm">
          <gl-link :href="$options.FEEDBACK_ISSUE_URL" target="_blank" rel="noopener noreferrer">{{
            s__('FeatureLibrary|Share feedback about this feature library')
          }}</gl-link>
        </div>
      </div>
    </template>
  </gl-modal>
</template>
