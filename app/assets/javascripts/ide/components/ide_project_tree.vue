<script>
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
    <div class="multi-file-commit-panel-inner-scroll">
      <branches-tree
        v-for="branch in project.branches"
        :key="branch.name"
        :project-id="project.path_with_namespace"
        :branch="branch"
      />
    </div>
  </div>
</template>
