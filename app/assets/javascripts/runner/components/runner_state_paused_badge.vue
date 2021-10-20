<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { I18N_PAUSED_RUNNER_DESCRIPTION } from '../constants';

export default {
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    I18N_PAUSED_RUNNER_DESCRIPTION,
  },
};
</script>
<template>
  <gl-badge
    v-gl-tooltip="$options.i18n.I18N_PAUSED_RUNNER_DESCRIPTION"
    variant="danger"
    v-bind="$attrs"
  >
    {{ s__('Runners|paused') }}
  </gl-badge>
</template>
