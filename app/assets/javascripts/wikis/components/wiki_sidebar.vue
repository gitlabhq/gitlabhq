<script>
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WikiSidebarHeader from './wiki_sidebar_header.vue';
import WikiSidebarEntries from './wiki_sidebar_entries.vue';
import WikiSidebarToggle from './wiki_sidebar_toggle.vue';

const LOCAL_STORAGE_STATE_KEY = 'wiki-sidebar-expanded';

const sidebarExpandedByDefault = () => {
  return PanelBreakpointInstance.getBreakpointSize() === 'xl';
};

export default {
  name: 'WikiSidebar',
  components: { WikiSidebarHeader, WikiSidebarEntries, WikiSidebarToggle },
  mixins: [glFeatureFlagsMixin()],
  inject: ['hasCustomSidebar'],
  data() {
    return {
      initialExpandedState:
        JSON.parse(localStorage.getItem('wiki-sidebar-open')) ?? sidebarExpandedByDefault(),
      pagesListExpanded: this.getInitialPagesListState(),
    };
  },
  computed: {
    initialClasses() {
      return this.initialExpandedState ? 'sidebar-expanded' : 'sidebar-collapsed';
    },
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
    class="wiki-sidebar js-wiki-sidebar gl-z-200"
    :class="initialClasses"
    data-offset-top="50"
    data-spy="affix"
  >
    <wiki-sidebar-toggle
      v-if="glFeatures.wikiFloatingSidebarToggle"
      class="gl-fixed gl-top-4 gl-ml-4 gl-hidden @lg/panel:gl-block"
      action="open"
    />
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
