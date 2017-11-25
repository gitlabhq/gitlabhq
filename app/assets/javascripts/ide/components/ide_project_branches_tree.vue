<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import RepoTree from './ide_repo_tree.vue';

export default {
  components: {
    RepoTree,
  },
  props: {
    branch: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <div class="branch-header">
      <strong class="clgray">
        {{ branch.name }}
      </strong>
    </div>
    <div>
      <repo-tree
        :treeId="branch.treeId"/>
    </div>
  </div>
</template>
