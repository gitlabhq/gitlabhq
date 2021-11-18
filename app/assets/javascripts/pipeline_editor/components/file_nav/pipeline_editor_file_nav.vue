<script>
import BranchSwitcher from './branch_switcher.vue';

export default {
  components: {
    BranchSwitcher,
  },
  props: {
    hasUnsavedChanges: {
      type: Boolean,
      required: false,
      default: false,
    },
    shouldLoadNewBranch: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>
<template>
  <div class="gl-mb-4">
    <branch-switcher
      :has-unsaved-changes="hasUnsavedChanges"
      :should-load-new-branch="shouldLoadNewBranch"
      v-on="$listeners"
    />
  </div>
</template>
