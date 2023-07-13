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
  props: {
    href: {
      type: String,
      required: false,
      default: null,
    },
  },
  I18N_EDIT,
};
</script>

<template>
  <gl-button
    v-if="href"
    v-gl-tooltip="$options.I18N_EDIT"
    :aria-label="$options.I18N_EDIT"
    :href="href"
    icon="pencil"
    v-on="$listeners"
  />
</template>
