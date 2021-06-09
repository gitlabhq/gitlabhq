<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '../../locale';

export default {
  i18n: {
    removesBranchText: __('The source branch will be deleted'),
    tooltipTitle: __('A user with write access to the source branch selected this option'),
  },
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
};
</script>

<template>
  <p v-once class="mr-info-list gl-ml-7 gl-pb-5 gl-mb-0">
    <span class="status-text">
      {{ $options.i18n.removesBranchText }}
    </span>
    <gl-icon
      v-gl-tooltip.hover
      :title="$options.i18n.tooltipTitle"
      :aria-label="$options.i18n.tooltipTitle"
      name="question-o"
    />
  </p>
</template>
