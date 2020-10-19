<script>
import { GlIcon, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '../../locale';

export default {
  i18n: {
    removesBranchText: __('%{strongStart}Deletes%{strongEnd} source branch'),
    tooltipTitle: __('A user with write access to the source branch selected this option'),
  },
  components: {
    GlIcon,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    <gl-icon
      v-gl-tooltip.hover
      :title="$options.i18n.tooltipTitle"
      :aria-label="$options.i18n.tooltipTitle"
      name="question-o"
    />
  </p>
</template>
