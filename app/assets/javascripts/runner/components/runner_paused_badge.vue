<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { I18N_PAUSED_DESCRIPTION } from '../constants';

export default {
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  I18N_PAUSED_DESCRIPTION,
};
</script>
<template>
  <gl-badge v-gl-tooltip="$options.I18N_PAUSED_DESCRIPTION" variant="danger" v-bind="$attrs">
    {{ s__('Runners|paused') }}
  </gl-badge>
</template>
