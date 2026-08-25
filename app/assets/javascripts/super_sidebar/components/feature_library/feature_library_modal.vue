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
import { HIDDEN_NAV_ITEM_CLASS, PANEL_TYPES } from '../../constants';
import ScrollScrim from '../scroll_scrim.vue';
import { FEEDBACK_ISSUE_URL, MODAL_ID, ITEMS_PER_RENDER_FRAME } from './constants';
import { rankSearchResults } from './search';
import FeatureLibraryItem from './feature_library_item.vue';

const SETTINGS_MENU_ID = 'settings_menu';
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
  i18n: {
    geminiSearching: s__('FeatureLibrary|Searching with Gemini …'),
    geminiEmptyState: s__(
      "FeatureLibrary|Gemini couldn't find a matching feature. Try different keywords.",
    ),
  },
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
      if (!this.trimmedQuery) return this.catalog;

      return rankSearchResults({
        catalog: this.catalog,
        query: this.trimmedQuery,
        synonymIds: this.searchResultIds,
      });
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
    showGeminiTopBorder() {
      // showEmptyState already requires !showGeminiEmptyState, so the two are
      // mutually exclusive: no need to check showEmptyState separately here.
      return !this.isGeminiSearching && !this.showGeminiEmptyState;
    },
    geminiStatusMessage() {
      if (!this.showGeminiSection) {
        return '';
      }

      if (this.isGeminiSearching) {
        return this.$options.i18n.geminiSearching;
      }

      if (this.geminiErrorMessage) {
        return this.geminiErrorMessage;
      }

      if (this.showGeminiEmptyState) {
        return this.$options.i18n.geminiEmptyState;
      }

      if (this.geminiItems.length > 0) {
        return s__('FeatureLibrary|Gemini found matching features.');
      }

      return '';
    },
  },
  beforeDestroy() {
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
      if (!this.trimmedQuery || this.isSearching || !this.filteredItems.length) return;

      // Move focus into the results instead of navigating away: focusing the
      // first result lets keyboard users continue from there
      // (e.g. Tab to its pin action, or Enter again to open it).
      //
      // Match by id rather than taking $refs.searchResultItems[0]: Vue 2's
      // v-for ref arrays reflect registration order, which isn't guaranteed
      // to track the current (re-ranked) filteredItems order.
      const [firstDisplayedItem] = this.filteredItems;
      const firstResultComponent = (this.$refs.searchResultItems || []).find(
        (component) => component.item.id === firstDisplayedItem.id,
      );
      firstResultComponent?.focus();
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

      // The "Search with Gemini" button unmounts once searching starts, which would
      // otherwise silently drop keyboard focus to <body>. Return focus to the search
      // input, which remains mounted throughout.
      this.$refs.searchBox?.focusInput?.();

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

      // Re-focusing as the Hide button unmounts along with the rest of the Gemini section
      this.$refs.searchBox?.focusInput?.();
    },
  },
};
</script>

<template>
  <gl-modal
    :modal-id="$options.modalId"
    :aria-label="s__('FeatureLibrary|GitLab features')"
    :hide-footer="!showFooter"
    modal-class="feature-library-modal"
    body-class="gl-flex gl-flex-col gl-overflow-hidden"
    size="lg"
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
            ref="searchResultItems"
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
        <!-- Always present in the DOM (not gated by showGeminiSection) so screen
             readers pick up the *first* content change: a live region that enters
             the DOM with content already set is not reliably announced. -->
        <div
          role="status"
          aria-live="polite"
          aria-atomic="true"
          data-testid="gemini-status-region"
          class="gl-sr-only"
        >
          {{ geminiStatusMessage }}
        </div>
        <template v-if="showGeminiSection">
          <div data-testid="gemini-section" :class="{ 'gl-border-t': showGeminiTopBorder }">
            <div v-if="showGeminiHeader" class="gl-flex gl-items-center gl-justify-between gl-py-4">
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
                <gl-loading-icon size="sm" aria-hidden="true" data-testid="gemini-loading" />
                <span aria-hidden="true">{{ $options.i18n.geminiSearching }}</span>
              </template>
              <span v-else-if="geminiErrorMessage" aria-hidden="true" data-testid="gemini-error">
                {{ geminiErrorMessage }}
              </span>
              <span v-else aria-hidden="true" data-testid="gemini-empty-state">
                {{ $options.i18n.geminiEmptyState }}
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
          <gl-link :href="$options.FEEDBACK_ISSUE_URL" show-external-icon target="_blank">{{
            s__('FeatureLibrary|Share feedback about this feature library')
          }}</gl-link>
        </div>
      </div>
    </template>
  </gl-modal>
</template>
