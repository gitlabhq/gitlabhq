<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import NewDropdown from './new_dropdown/index.vue';
import IdeTreeList from './ide_tree_list.vue';

export default {
  components: {
    NewDropdown,
    IdeTreeList,
  },
  computed: {
    ...mapState(['currentBranchId']),
    ...mapGetters(['currentProject', 'currentTree', 'activeFile']),
  },
  mounted() {
    if (this.activeFile && this.activeFile.pending) {
      this.$router.push(`/project${this.activeFile.url}`, () => {
        this.updateViewer('editor');
      });
    }
  },
  methods: {
    ...mapActions(['updateViewer']),
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
      />
    </template>
  </ide-tree-list>
</template>
