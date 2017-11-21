<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import RepoTree from './ide_repo_tree.vue';

export default {
  components: {
    RepoTree,
  },
  created() {
    //window.addEventListener('popstate', this.popHistoryState);
  },
  destroyed() {
    //window.removeEventListener('popstate', this.popHistoryState);
  },
};
</script>

<template>
<div class="nav-sidebar">
  <div class="nav-sidebar-inner-scroll" style="overflow-y: scroll;">
    <div class="context-header">
      <a title="Html5 Boilerplate" href="/h5bp/html5-boilerplate">
        <div class="avatar-container s40 project-avatar">
          <img alt="Html5 Boilerplate" class="avatar s40 avatar-tile js-lazy-loaded" src="/uploads/-/system/project/avatar/8/hodor.jpg">
        </div>
        <div class="sidebar-context-title">
          Html5 Boilerplate
        </div>
      </a>
    </div>
    <div class="ide-content-holder tree-content-holder-mini">
      <repo-tree/>
    </div>
    <a class="toggle-sidebar-button js-toggle-sidebar" role="button" title="Toggle sidebar" type="button">
      <svg class=" icon-angle-double-left"><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/assets/icons-f1e1e3187fbe3fe3aa42a17cb2558778f1a2ddc2a1914f0ea7ea59d27b4e425c.svg#angle-double-left"></use></svg>
      <svg class=" icon-angle-double-right"><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/assets/icons-f1e1e3187fbe3fe3aa42a17cb2558778f1a2ddc2a1914f0ea7ea59d27b4e425c.svg#angle-double-right"></use></svg>
      <span class="collapse-text">Collapse sidebar</span>
    </a>
  </div>
</div>
</template>
