<script>
import WikiSidebarHeader from './wiki_sidebar_header.vue';
import WikiSidebarEntries from './wiki_sidebar_entries.vue';

const LOCAL_STORAGE_STATE_KEY = 'wiki-sidebar-expanded';

export default {
  name: 'WikiSidebar',
  components: { WikiSidebarHeader, WikiSidebarEntries },
  inject: ['hasCustomSidebar'],
  data() {
    return {
      pagesListExpanded: this.getInitialPagesListState(),
    };
  },
  watch: {
    pagesListExpanded(newValue) {
      this.persistPagesListState(newValue);
    },
  },
  methods: {
    getInitialPagesListState() {
      // If no custom sidebar, always show pages list
      if (!this.hasCustomSidebar) return true;

      // Restore from localStorage if available
      const savedState = localStorage.getItem(LOCAL_STORAGE_STATE_KEY);
      return savedState === 'expanded';
    },
    persistPagesListState(expanded) {
      if (expanded) {
        localStorage.setItem(LOCAL_STORAGE_STATE_KEY, 'expanded');
      } else {
        localStorage.removeItem(LOCAL_STORAGE_STATE_KEY);
      }
    },
  },
};
</script>

<template>
  <aside
    :aria-label="__('Wiki')"
    class="wiki-sidebar js-wiki-sidebar sidebar-collapsed"
    data-offset-top="50"
    data-spy="affix"
  >
    <div class="js-wiki-sidebar-resizer"></div>
    <div class="sidebar-container">
      <div class="blocks-container">
        <wiki-sidebar-header
          :pages-list-expanded="pagesListExpanded"
          @toggle-pages-list="pagesListExpanded = !pagesListExpanded"
        />
        <wiki-sidebar-entries :pages-list-expanded="pagesListExpanded" />
      </div>
    </div>
  </aside>
</template>
