<script>
import { GlBadge, GlSkeletonLoader, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { NO_VALUE } from './utils/stat';

export default {
  name: 'TrendPresenter',
  components: {
    GlBadge,
    GlSkeletonLoader,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    // An empty config means the row has no counterpart in the previous period, so its change
    // is unknown. Kept distinct from a neutral `0%` badge, which means the row did not move.
    // A `pending` config means that is not known yet, so it shows a skeleton, not the dash.
    data: {
      required: true,
      type: Object,
    },
  },
  computed: {
    // Keyboard and screen reader users can't reach the tooltip, and only the arrow shows the
    // direction, so screen readers get the tooltip text in place of the visible cell.
    description() {
      return this.data.text ? this.data.metaTooltip : s__('Glql|No data for the previous period');
    },
  },
  NO_VALUE,
};
</script>
<template>
  <div v-if="data.pending" data-testid="trend-pending">
    <gl-skeleton-loader :width="60" :lines="1" :equal-width-lines="true" />
  </div>
  <span v-else>
    <gl-badge
      v-if="data.text"
      v-gl-tooltip
      :title="description"
      :variant="data.variant"
      :icon="data.metaIcon"
      aria-hidden="true"
      data-testid="trend-badge"
    >
      {{ data.text }}
    </gl-badge>
    <span
      v-else
      v-gl-tooltip
      :title="description"
      aria-hidden="true"
      class="gl-text-subtle"
      data-testid="trend-unknown"
      >{{ $options.NO_VALUE }}</span
    >
    <span class="gl-sr-only" data-testid="trend-description">{{ description }}</span>
  </span>
</template>
