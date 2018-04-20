<script>
import { mapState, mapGetters } from 'vuex';
import NewDropdown from './new_dropdown/index.vue';
import IdeTreeList from './ide_tree_list.vue';

export default {
  components: {
    NewDropdown,
    IdeTreeList,
  },
  computed: {
    ...mapState(['currentBranchId']),
    ...mapGetters(['currentProject']),
  },
};
</script>

<template>
  <ide-tree-list
    viewer-type="editor"
  >
    <template
      slot="header"
    >
      {{ __('Edit') }}
      <new-dropdown
        :project-id="currentProject.name_with_namespace"
        :branch="currentBranchId"
        path=""
      />
    </template>
  </ide-tree-list>
</template>
