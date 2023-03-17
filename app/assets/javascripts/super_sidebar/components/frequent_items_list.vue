<script>
import * as Sentry from '@sentry/browser';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import AccessorUtilities from '~/lib/utils/accessor';
import { getTopFrequentItems, formatContextSwitcherItems } from '../utils';
import NavItem from './nav_item.vue';

export default {
  components: {
    ProjectAvatar,
    NavItem,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    searchTitle: {
      type: String,
      required: true,
    },
    pristineText: {
      type: String,
      required: true,
    },
    noResultsText: {
      type: String,
      required: true,
    },
    storageKey: {
      type: String,
      required: true,
    },
    maxItems: {
      type: Number,
      required: true,
    },
    isSearch: {
      type: Boolean,
      required: false,
      default: false,
    },
    searchResults: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      cachedFrequentItems: [],
    };
  },
  computed: {
    items() {
      return this.isSearch ? this.searchResults : this.cachedFrequentItems;
    },
    isEmpty() {
      return !this.items.length;
    },
    listTitle() {
      return this.isSearch ? this.searchTitle : this.title;
    },
    emptyText() {
      return this.isSearch ? this.noResultsText : this.pristineText;
    },
  },
  created() {
    this.getItemsFromLocalStorage();
  },
  methods: {
    getItemsFromLocalStorage() {
      if (!AccessorUtilities.canUseLocalStorage()) {
        return;
      }
      try {
        const parsedCachedFrequentItems = JSON.parse(localStorage.getItem(this.storageKey));
        const topFrequentItems = getTopFrequentItems(parsedCachedFrequentItems, this.maxItems);
        this.cachedFrequentItems = formatContextSwitcherItems(topFrequentItems);
      } catch (e) {
        Sentry.captureException(e);
      }
    },
  },
};
</script>

<template>
  <li class="gl-border-t gl-border-gray-50 gl-mx-3 gl-py-3">
    <div
      data-testid="list-title"
      aria-hidden="true"
      class="gl-text-transform-uppercase gl-text-secondary gl-font-weight-bold gl-font-xs gl-line-height-12 gl-letter-spacing-06em gl-my-3"
    >
      {{ listTitle }}
    </div>
    <div v-if="isEmpty" data-testid="empty-text" class="gl-text-gray-500 gl-font-sm gl-my-3">
      {{ emptyText }}
    </div>
    <ul :aria-label="title" class="gl-p-0 gl-list-style-none">
      <nav-item
        v-for="item in items"
        :key="item.id"
        :item="item"
        :link-classes="{ 'gl-py-2!': true }"
      >
        <template #icon>
          <project-avatar
            :project-id="item.id"
            :project-name="item.title"
            :project-avatar-url="item.avatar"
            :size="24"
            aria-hidden="true"
          />
        </template>
      </nav-item>
      <slot name="view-all-items"></slot>
    </ul>
  </li>
</template>
