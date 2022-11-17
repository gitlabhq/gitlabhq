<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { I18N_EDIT } from '../constants';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  I18N_EDIT,
};
</script>

<template>
  <gl-button
    v-gl-tooltip="$options.I18N_EDIT"
    v-bind="$attrs"
    :aria-label="$options.I18N_EDIT"
    icon="pencil"
    v-on="$listeners"
  />
</template>
