<script>
import tooltip from '../../vue_shared/directives/tooltip';
import { __ } from '../../locale';

export default {
  directives: {
    tooltip,
  },
  created() {
    this.removesBranchText = __('<strong>Deletes</strong> source branch');
    this.tooltipTitle = __('A user with write access to the source branch selected this option');
  },
};
</script>

<template>
  <p v-once class="mr-info-list mr-links append-bottom-0">
    <span class="status-text" v-html="removesBranchText"> </span>
    <i v-tooltip :title="tooltipTitle" :aria-label="tooltipTitle" class="fa fa-question-circle">
    </i>
  </p>
</template>
