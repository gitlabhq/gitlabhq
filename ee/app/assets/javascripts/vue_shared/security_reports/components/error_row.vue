<script>
import CiIcon from '~/vue_shared/components/ci_icon.vue';

/**
 * Renders the error row for each security report
 */
export default {
  name: 'SecurityErrorRow',
  components: {
    CiIcon,
  },
  computed: {
    iconStatus() {
      return {
        group: 'warning',
        icon: 'status_warning',
      };
    },
  },
};
</script>
<template>
  <div class="report-block-list-issue">
    <div class="report-block-list-icon append-right-10 prepend-left-10">
      <ci-icon :status="iconStatus" />
    </div>
    <div class="report-block-list-issue-description">
      {{ __("There was an error loading results") }}
    </div>
  </div>
</template>
