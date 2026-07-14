<script>
import {
  GlModal,
  GlSearchBoxByType,
  GlScrollableTabs,
  GlTab,
  GlEmptyState,
  GlLink,
  GlLoadingIcon,
} from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { HTTP_STATUS_TOO_MANY_REQUESTS } from '~/lib/utils/http_status';
import { onboardingFeatureLibrarySearchPath } from '~/lib/utils/path_helpers/feature_library';
import { InternalEvents } from '~/tracking';
import {
  EVENT_OPEN_FEATURE_LIBRARY_MODAL,
  EVENT_SEARCH_FEATURES_IN_FEATURE_LIBRARY_MODAL,
  EVENT_CLICK_CATEGORY_TAB_IN_FEATURE_LIBRARY_MODAL,
  EVENT_PIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
  EVENT_UNPIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
  EVENT_NAVIGATE_TO_FEATURE_FROM_FEATURE_LIBRARY_MODAL,
} from '../../tracking_constants';
import {
  ALL_CATEGORY,
  ALL_CATEGORY_ID,
  FEEDBACK_ISSUE_URL,
  MODAL_ID,
  ITEMS_PER_RENDER_FRAME,
} from './constants';
import FeatureLibraryItem from './feature_library_item.vue';

const SETTINGS_MENU_ID = 'settings_menu';
const trackingMixin = InternalEvents.mixin();
const MIN_SEARCH_QUERY_LENGTH = 2;

export default {
  name: 'FeatureLibraryModal',
  components: {
    GlModal,
    GlSearchBoxByType,
    GlScrollableTabs,
    GlTab,
    GlEmptyState,
    GlLink,
    GlLoadingIcon,
    FeatureLibraryItem,
  },
  mixins: [trackingMixin],
  modalId: MODAL_ID,
  DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
  FEEDBACK_ISSUE_URL,
  inject: {
    panelType: { default: '' },
  },
  props: {
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
      activeCategoryId: ALL_CATEGORY_ID,
      searchResultIds: [],
      isSearching: false,
      latestQuery: null,
      renderLimit: ITEMS_PER_RENDER_FRAME,
      revealFrameId: null,
    };
  },
  computed: {
    trimmedQuery() {
      return this.searchQuery.trim();
    },
    libraryCategories() {
      return [ALL_CATEGORY, ...this.catalogSections.map(({ id, title }) => ({ id, label: title }))];
    },
    catalogSections() {
      return this.sections
        .map((section) => ({
          ...section,
          items: section.items || [],
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

      const inCategory = (item) =>
        this.activeCategoryId === ALL_CATEGORY_ID || item.category === this.activeCategoryId;

      if (!q) return this.catalog.filter(inCategory);

      const textMatches = (text = '') => text.toLowerCase().includes(q);

      // Synonym matches from endpoint come first: backend-ranked (exact -> prefix -> contains).
      const synonymMatches = this.searchResultIds
        .map((id) => this.catalogById[id])
        .filter((item) => item && inCategory(item));

      // Direct title/description matches follow, excluding any already surfaced as synonyms.
      const synonymIds = new Set(synonymMatches.map((item) => item.id));
      const directMatches = this.catalog.filter(
        (item) =>
          inCategory(item) &&
          !synonymIds.has(item.id) &&
          (textMatches(item.title) || textMatches(item.description)),
      );

      return [...synonymMatches, ...directMatches];
    },
    showEmptyState() {
      return (
        !this.isSearching &&
        this.trimmedQuery.length >= MIN_SEARCH_QUERY_LENGTH &&
        this.filteredItems.length === 0
      );
    },
    emptyStateTitle() {
      if (this.activeCategoryId !== ALL_CATEGORY_ID) {
        const activeCategory = this.libraryCategories.find(
          (category) => category.id === this.activeCategoryId,
        );

        if (activeCategory) {
          return sprintf(s__('FeatureLibrary|No matches in %{category}'), {
            category: activeCategory.label,
          });
        }
      }

      return s__('FeatureLibrary|No features match your search');
    },
    visibleItems() {
      if (this.trimmedQuery) return this.filteredItems;
      return this.filteredItems.slice(0, this.renderLimit);
    },
  },
  beforeUnmount() {
    this.cancelReveal();
  },
  methods: {
    isPinned(itemId) {
      return this.currentPinnedIds.includes(itemId);
    },
    onShown() {
      this.revealRemainingItems();
      this.trackEvent(EVENT_OPEN_FEATURE_LIBRARY_MODAL);
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
    onTabClick(categoryId) {
      this.activeCategoryId = categoryId;
      this.trackEvent(EVENT_CLICK_CATEGORY_TAB_IN_FEATURE_LIBRARY_MODAL, {
        label: categoryId,
      });
    },
    resetSearchState() {
      this.isSearching = false;
      this.latestQuery = null;
      this.searchResultIds = [];
    },
    onSearchInput(value) {
      this.searchQuery = value;
      const query = value.trim();
      this.activeCategoryId = ALL_CATEGORY_ID;

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
      this.cancelReveal();
      this.searchQuery = '';
      this.activeCategoryId = ALL_CATEGORY_ID;
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
  },
};
</script>

<template>
  <gl-modal
    :modal-id="$options.modalId"
    :aria-label="s__('FeatureLibrary|GitLab features')"
    :hide-footer="!showFeedbackLink"
    modal-class="feature-library-modal gl-backdrop-blur-sm gl-px-2 sm:gl-px-5"
    body-class="gl-flex gl-flex-col"
    size="lg"
    scrollable
    hide-header
    @shown="onShown"
    @hidden="onHidden"
  >
    <gl-search-box-by-type
      :value="searchQuery"
      :placeholder="s__('FeatureLibrary|Search GitLab features')"
      :debounce="$options.DEFAULT_DEBOUNCE_AND_THROTTLE_MS"
      class="gl-mb-4 gl-mt-3"
      @input="onSearchInput"
    />
    <gl-scrollable-tabs>
      <gl-tab
        v-for="cat in libraryCategories"
        :key="cat.id"
        :title="cat.label"
        :active="cat.id === activeCategoryId"
        @click="onTabClick(cat.id)"
      />
    </gl-scrollable-tabs>
    <div
      data-testid="feature-library-scroll-area"
      class="feature-library-scroll-area gl-min-h-0 gl-grow gl-overflow-y-auto"
    >
      <ul
        v-if="!isSearching && filteredItems.length > 0"
        data-testid="feature-library-grid"
        class="gl-grid gl-list-none gl-grid-cols-1 gl-gap-3 gl-p-0 sm:gl-grid-cols-2 md:gl-grid-cols-3"
      >
        <feature-library-item
          v-for="item in visibleItems"
          :key="item.id"
          :item="item"
          :pinned="isPinned(item.id)"
          @pin-toggle="onPinToggle"
          @navigate="onNavigate"
        />
      </ul>
      <gl-loading-icon v-if="isSearching" size="sm" class="gl-mt-3" data-testid="search-loading" />
      <gl-empty-state
        v-if="showEmptyState"
        :title="emptyStateTitle"
        :description="s__('FeatureLibrary|Try a different search term or category.')"
      />
    </div>
    <template v-if="showFeedbackLink" #modal-footer>
      <div class="gl-w-full gl-text-center gl-text-sm">
        <gl-link :href="$options.FEEDBACK_ISSUE_URL" target="_blank" rel="noopener noreferrer">{{
          s__('FeatureLibrary|Share feedback about this feature')
        }}</gl-link>
      </div>
    </template>
  </gl-modal>
</template>
