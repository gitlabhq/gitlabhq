<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import ProjectTree from './ide_project_tree.vue';

export default {
  components: {
    ProjectTree,
  },
  computed: {
    ...mapState([
      'loading',
    ]),
    ...mapState({
      projects(state) {
        return state.projects;
      },
    }),
  },
};
</script>

<template>
<div class="nav-sidebar">
  <div class="nav-sidebar-inner-scroll" style="overflow-y: scroll;">
    
    <project-tree
      v-for="(project, index) in projects"
      :key="project.id"
      :project="project"/>

    <a class="toggle-sidebar-button js-toggle-sidebar" role="button" title="Toggle sidebar" type="button">
      <svg class=" icon-angle-double-left"><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/assets/icons-f1e1e3187fbe3fe3aa42a17cb2558778f1a2ddc2a1914f0ea7ea59d27b4e425c.svg#angle-double-left"></use></svg>
      <svg class=" icon-angle-double-right"><use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/assets/icons-f1e1e3187fbe3fe3aa42a17cb2558778f1a2ddc2a1914f0ea7ea59d27b4e425c.svg#angle-double-right"></use></svg>
      <span class="collapse-text">Collapse sidebar</span>
    </a>
  </div>
</div>
</template>
