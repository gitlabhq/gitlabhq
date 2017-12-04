<script>
import RepoTree from './ide_repo_tree.vue';
import Icon from '../../vue_shared/components/icon.vue';

export default {
  components: {
    RepoTree,
    Icon,
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
  <div class="branch-container">
    <div class="branch-header">
      <icon
        name="branch"
        :size="12">
      </icon>
      {{ branch.name }}
    </div>
    <div>
      <repo-tree
        :treeId="branch.treeId"/>
    </div>
  </div>
</template>
