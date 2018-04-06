<script>
import icon from '~/vue_shared/components/icon.vue';
import repoTree from './ide_repo_tree.vue';
import newDropdown from './new_dropdown/index.vue';

export default {
  components: {
    repoTree,
    icon,
    newDropdown,
  },
  props: {
    projectId: {
      type: String,
      required: true,
    },
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
      <div class="branch-header-title str-truncated ref-name">
        <icon
          name="branch"
          :size="12"
        />
        {{ branch.name }}
      </div>
      <div class="branch-header-btns">
        <new-dropdown
          :project-id="projectId"
          :branch="branch.name"
          path=""
        />
      </div>
    </div>
    <repo-tree
      v-if="branch.tree"
      :tree="branch.tree"
    />
  </div>
</template>
