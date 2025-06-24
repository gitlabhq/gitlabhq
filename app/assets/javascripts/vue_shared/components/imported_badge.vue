<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  tooltip: s__('BulkImport|This item was imported from another instance.'),
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    textOnly: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <span v-if="textOnly" v-gl-tooltip="$options.tooltip">
    {{ __('Imported') }}
  </span>
  <gl-badge v-else v-gl-tooltip="$options.tooltip" class="gl-shrink-0">
    {{ __('Imported') }}
  </gl-badge>
</template>
