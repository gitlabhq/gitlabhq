<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import RepoTree from './ide_repo_tree.vue';

export default {
  components: {
    RepoTree,
  },
  
};
</script>

<template>
  <div>
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
  </div>
</template>
