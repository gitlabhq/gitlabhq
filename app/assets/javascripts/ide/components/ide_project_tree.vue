<script>
import { mapGetters } from 'vuex';
import BranchesTree from './ide_project_branches_tree.vue';

export default {
  components: {
    BranchesTree,
  },
  computed: {
    ...mapGetters(['currentProjectWithTree']),
  },
};
</script>

<template>
  <div class="projects-sidebar">
    <branches-tree
      v-for="branch in currentProjectWithTree.branches"
      :key="branch.name"
      :project-id="currentProjectWithTree.path_with_namespace"
      :branch="branch"
    />
  </div>
</template>
