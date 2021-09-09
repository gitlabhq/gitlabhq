<script>
import BranchSwitcher from './branch_switcher.vue';

export default {
  components: {
    BranchSwitcher,
  },
};
</script>
<template>
  <div class="gl-mb-4">
    <branch-switcher v-on="$listeners" />
  </div>
</template>
