<script>
import { GlButton, GlSkeletonLoader, GlSearchBoxByType } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { sidebarEntriesToTree } from '../utils';
import WikiSidebarEntry from './wiki_sidebar_entry.vue';

const SIDEBAR_LIMIT = 15;

export default {
  components: {
    WikiSidebarEntry,
    GlButton,
    GlSkeletonLoader,
    GlSearchBoxByType,
  },
  inject: ['sidebarPagesApi', 'hasCustomSidebar', 'viewAllPagesPath'],
  props: {},

  data() {
    return {
      allEntries: [],
      entries: [],
      totalCount: 0,
      isLoadingContent: false,
      searchTerm: '',
    };
  },

  computed: {
    countExceedsSidebarLimit() {
      return this.totalCount > this.$options.SIDEBAR_LIMIT && !this.searchTerm;
    },
  },

  watch: {
    async searchTerm() {
      this.entries = sidebarEntriesToTree(
        this.allEntries
          .filter((entry) => entry.title.toLowerCase().includes(this.searchTerm.toLowerCase()))
          .slice(0, SIDEBAR_LIMIT),
      );
    },
  },

  async mounted() {
    this.isLoadingContent = true;
    let { data: entries } = await axios.get(this.sidebarPagesApi);
    this.isLoadingContent = false;

    entries = entries.filter((entry) => entry.slug !== '_sidebar');

    this.entries = sidebarEntriesToTree(entries.slice(0, SIDEBAR_LIMIT));
    this.totalCount = entries.length;
    this.allEntries = entries;
  },
  SIDEBAR_LIMIT,
};
</script>
<template>
  <div v-if="isLoadingContent && !hasCustomSidebar" class="gl-m-3">
    <gl-skeleton-loader />
  </div>
  <ul v-else class="wiki-pages" :class="{ 'gl-border-b !gl-pb-3': hasCustomSidebar }">
    <gl-search-box-by-type
      v-model.trim="searchTerm"
      :placeholder="s__('Wiki|Search pages')"
      class="gl-m-2"
      @keyup.prevent.stop
    />
    <wiki-sidebar-entry
      v-for="entry in entries"
      :key="entry.slug"
      :page="entry"
      :search-term="searchTerm"
    />
    <div v-if="countExceedsSidebarLimit" class="gl-text-secondary gl-mt-3 gl-ml-3 gl-inline-block">
      {{ sprintf(s__('Wiki|+ %{count} more'), { count: totalCount - $options.SIDEBAR_LIMIT }) }}
      <span class="gl-px-2">&middot;</span>
    </div>
    <gl-button
      v-if="totalCount"
      category="tertiary"
      size="small"
      variant="link"
      data-testid="view-all-pages-button"
      :href="viewAllPagesPath"
      :class="{
        'gl-ml-3 gl-mt-3': !countExceedsSidebarLimit,
        'gl-mt-n1 gl-inline-block': countExceedsSidebarLimit,
      }"
    >
      {{ s__('Wiki|View all pages') }}
    </gl-button>
    <div v-else class="gl-ml-3 gl-mt-3 gl-text-secondary">
      {{ s__('Wiki|There are no pages in this wiki yet') }}
    </div>
  </ul>
</template>
