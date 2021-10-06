<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { I18N_LOCKED_RUNNER_DESCRIPTION } from '../constants';

export default {
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    I18N_LOCKED_RUNNER_DESCRIPTION,
  },
};
</script>
<template>
  <gl-badge
    v-gl-tooltip="$options.i18n.I18N_LOCKED_RUNNER_DESCRIPTION"
    variant="warning"
    v-bind="$attrs"
  >
    {{ s__('Runners|locked') }}
  </gl-badge>
</template>
