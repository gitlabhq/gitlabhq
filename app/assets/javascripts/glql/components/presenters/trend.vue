<script>
import { GlBadge, GlSkeletonLoader, GlTooltipDirective } from '@gitlab/ui';
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
  NO_VALUE,
};
</script>
<template>
  <div v-if="data.pending" data-testid="trend-pending">
    <gl-skeleton-loader :width="60" :lines="1" :equal-width-lines="true" />
  </div>
  <gl-badge
    v-else-if="data.text"
    v-gl-tooltip
    :title="data.metaTooltip"
    :variant="data.variant"
    :icon="data.metaIcon"
    data-testid="trend-badge"
  >
    {{ data.text }}
  </gl-badge>
  <span v-else class="gl-text-subtle" data-testid="trend-unknown">{{ $options.NO_VALUE }}</span>
</template>
