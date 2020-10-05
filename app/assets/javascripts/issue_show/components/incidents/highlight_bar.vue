<script>
import { GlLink, GlTooltipDirective } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime_utility';

export default {
  components: {
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    alert: {
      type: Object,
      required: true,
    },
  },
  computed: {
    startTime() {
      return formatDate(this.alert.startedAt, 'yyyy-mm-dd Z');
    },
  },
};
</script>

<template>
  <div
    class="gl-border-solid gl-border-1 gl-border-gray-100 gl-p-5 gl-mb-3 gl-rounded-base gl-display-flex gl-justify-content-space-between gl-xs-flex-direction-column"
  >
    <div class="gl-pr-3">
      <span class="gl-font-weight-bold">{{ s__('HighlightBar|Original alert:') }}</span>
      <gl-link v-gl-tooltip :title="alert.title" :href="alert.detailsUrl">
        #{{ alert.iid }}
      </gl-link>
    </div>

    <div class="gl-pr-3">
      <span class="gl-font-weight-bold">{{ s__('HighlightBar|Alert start time:') }}</span>
      {{ startTime }}
    </div>

    <div>
      <span class="gl-font-weight-bold">{{ s__('HighlightBar|Alert events:') }}</span>
      <span>{{ alert.eventCount }}</span>
    </div>
  </div>
</template>
