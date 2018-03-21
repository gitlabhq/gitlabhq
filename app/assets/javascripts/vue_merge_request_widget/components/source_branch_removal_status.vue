<script>
  import tooltip from '../../vue_shared/directives/tooltip';
  import { __ } from '../../locale';

  export default {
    directives: {
      tooltip,
    },
    created() {
      this.removesBranchText = __('<strong>Removes</strong> source branch');
      this.tooltipTitle = __('A user with write access to the source branch selected this option');
    },
  };
</script>

<template>
  <p
    v-once
    class="mr-info-list mr-links source-branch-removal-status append-bottom-0"
  >
    <span
      class="status-text"
      v-html="removesBranchText"
    >
    </span>
    <i
      v-tooltip
      class="fa fa-question-circle"
      :title="tooltipTitle"
      :aria-label="tooltipTitle"
    >
    </i>
  </p>
</template>
