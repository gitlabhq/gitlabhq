<script>
import { GlButton, GlSkeletonLoader, GlSearchBoxByType, GlCollapse } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { sidebarEntriesToTree } from '../utils';
import WikiSidebarEntry from './wiki_sidebar_entry.vue';

export default {
  components: {
    WikiSidebarEntry,
    GlButton,
    GlSkeletonLoader,
    GlSearchBoxByType,
    GlCollapse,
  },
  inject: [
    'sidebarPagesApi',
    'hasCustomSidebar',
    'viewAllPagesPath',
    'editing',
    'customSidebarContent',
  ],
  props: {
    pagesListExpanded: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
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
  <div class="wiki-pages-list-container">
    <gl-collapse :visible="pagesListExpanded" data-testid="pages-list-collapse">
      <div v-if="isLoadingContent && !hasCustomSidebar" class="gl-m-3">
        <gl-skeleton-loader />
      </div>
      <template v-else>
        <gl-search-box-by-type
          v-model.trim="searchTerm"
          :placeholder="s__('Wiki|Search pages')"
          class="gl-m-2"
          @keyup.prevent.stop
        />
        <ul class="wiki-pages" :class="{ 'gl-border-b !gl-pb-4': hasCustomSidebar }">
          <wiki-sidebar-entry
            v-for="entry in entries"
            :key="entry.slug"
            :page="entry"
            :search-term="searchTerm"
          />
        </ul>
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

        <div v-if="!editing" class="js-wiki-toc"></div>
      </template>
    </gl-collapse>
    <!-- customSidebarContent is sanitized by render_wiki_content() -->
    <div
      v-if="customSidebarContent"
      class="wiki-sidebar-custom-content gl-px-4 gl-pb-2 gl-pt-4"
      v-html="customSidebarContent /* eslint-disable-line vue/no-v-html */"
    ></div>
  </div>
</template>
