<script>
import WikiSidebarHeader from './wiki_sidebar_header.vue';
import WikiSidebarEntries from './wiki_sidebar_entries.vue';

export default {
  name: 'WikiSidebar',
  components: { WikiSidebarHeader, WikiSidebarEntries },
  inject: ['hasCustomSidebar'],
  data() {
    return {
      pagesListExpanded: !this.hasCustomSidebar,
    };
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
