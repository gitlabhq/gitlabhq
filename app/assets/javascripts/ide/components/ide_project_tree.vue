<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import BranchesTree from './ide_project_branches_tree.vue';

export default {
  components: {
    BranchesTree,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="projects-sidebar">
    <div class="context-header">
      <a title="Html5 Boilerplate" href="/h5bp/html5-boilerplate">
        <div class="avatar-container s40 project-avatar">
          <img alt="Html5 Boilerplate" class="avatar s40 avatar-tile js-lazy-loaded" src="/uploads/-/system/project/avatar/8/hodor.jpg">
        </div>
        <div class="sidebar-context-title">
          {{ project.name }}
        </div>
      </a>
    </div>
    <div>
      <branches-tree
        v-for="(branch, index) in project.branches"
        :key="branch.name"
        :branch="branch"/>
    </div>
  </div>
</template>
