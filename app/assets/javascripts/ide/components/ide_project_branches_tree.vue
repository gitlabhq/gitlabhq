<script>
import RepoTree from './ide_repo_tree.vue';
import Icon from '../../vue_shared/components/icon.vue';
import newDropdown from './new_dropdown/index.vue';

export default {
  components: {
    RepoTree,
    Icon,
    newDropdown
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
      <div class="branch-header-title">
        <icon
          name="branch"
          :size="12">
        </icon>
        {{ branch.name }}
      </div>
      <div class="branch-header-btns">
        <new-dropdown/>
      </div>
    </div>
    <div>
      <repo-tree
        :treeId="branch.treeId"/>
    </div>
  </div>
</template>
