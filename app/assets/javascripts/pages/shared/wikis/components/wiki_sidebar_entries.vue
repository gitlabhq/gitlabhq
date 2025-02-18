<script>
import { GlButton, GlSkeletonLoader, GlSearchBoxByType } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { sidebarEntriesToTree } from '../utils';
import WikiSidebarEntry from './wiki_sidebar_entry.vue';

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

  watch: {
    async searchTerm() {
      this.entries = sidebarEntriesToTree(
        this.allEntries.filter((entry) =>
          entry.title.toLowerCase().includes(this.searchTerm.toLowerCase()),
        ),
      );
    },
  },

  async mounted() {
    this.isLoadingContent = true;
    let { data: entries } = await axios.get(this.sidebarPagesApi);
    this.isLoadingContent = false;

    entries = entries.filter((entry) => entry.slug !== '_sidebar');

    this.entries = sidebarEntriesToTree(entries);
    this.totalCount = entries.length;
    this.allEntries = entries;
  },
};
</script>
<template>
  <div v-if="isLoadingContent && !hasCustomSidebar" class="gl-m-3">
    <gl-skeleton-loader />
  </div>
  <ul v-else class="wiki-pages" :class="{ 'gl-border-b !gl-pb-4': hasCustomSidebar }">
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
    <gl-button
      v-if="totalCount"
      category="tertiary"
      size="small"
      variant="link"
      data-testid="view-all-pages-button"
      class="gl-ml-4 gl-mt-3"
      :href="viewAllPagesPath"
    >
      {{ s__('Wiki|View all pages') }}
    </gl-button>
    <div v-else class="gl-ml-3 gl-mt-3 gl-text-subtle">
      {{ s__('Wiki|There are no pages in this wiki yet.') }}
    </div>
  </ul>
</template>
