<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'GroupAvatar',
  components: { GlIcon },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    tooltip: s__('Members|Private group information is only accessible to its members.'),
  },
};
</script>

<template>
  <gl-icon v-gl-tooltip="$options.i18n.tooltip" name="eye-slash" />
</template>
