<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { formatNumber, s__, sprintf } from '~/locale';

export default {
  name: 'RunnerManagersBadge',
  components: {
    GlBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    count: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    shouldShowBadge() {
      // runner managers can be grouped, but this information is only shown
      // when we have 2 or more.
      return this.count >= 2;
    },
    formattedCount() {
      return formatNumber(this.count);
    },
    tooltip() {
      return sprintf(s__('Runners|%{count} runners in this group'), {
        count: this.formattedCount,
      });
    },
  },
};
</script>
<template>
  <gl-badge
    v-if="shouldShowBadge"
    v-gl-tooltip="tooltip"
    variant="muted"
    icon="container-image"
    v-bind="$attrs"
  >
    {{ formattedCount }}
  </gl-badge>
</template>
