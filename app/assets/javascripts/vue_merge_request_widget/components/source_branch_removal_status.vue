<script>
import tooltip from '../../vue_shared/directives/tooltip';
import { __ } from '../../locale';
import { GlSprintf } from '@gitlab/ui';

export default {
  i18n: {
    removesBranchText: __('%{strongStart}Deletes%{strongEnd} source branch'),
    tooltipTitle: __('A user with write access to the source branch selected this option'),
  },
  components: {
    GlSprintf,
  },
  directives: {
    tooltip,
  },
};
</script>

<template>
  <p v-once class="mr-info-list mr-links gl-mb-0">
    <span class="status-text">
      <gl-sprintf :message="$options.i18n.removesBranchText">
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
      </gl-sprintf>
    </span>
    <i
      v-tooltip
      :title="$options.i18n.tooltipTitle"
      :aria-label="$options.i18n.tooltipTitle"
      class="fa fa-question-circle"
    >
    </i>
  </p>
</template>
