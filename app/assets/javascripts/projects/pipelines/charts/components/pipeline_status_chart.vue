<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import {
  DATA_VIZ_GREEN_500,
  DATA_VIZ_MAGENTA_600,
  DATA_VIZ_BLUE_500,
} from '@gitlab/ui/src/tokens/build/js/tokens';
import { s__ } from '~/locale';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';

export default {
  components: {
    GlLoadingIcon,
    GlStackedColumnChart,
  },
  props: {
    timeSeries: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    data() {
      const groupBy = [];

      const bars = [
        { name: s__('Pipeline|Successful'), data: [] },
        { name: s__('Pipeline|Failed'), data: [] },
        { name: s__('Pipeline|Other (Cancelled, Skipped)'), data: [] },
      ];

      this.timeSeries.forEach(({ label, successCount, failedCount, otherCount }) => {
        groupBy.push(label);
        bars[0].data.push(successCount);
        bars[1].data.push(failedCount);
        bars[2].data.push(otherCount);
      });

      return { groupBy, bars };
    },
    groupBy() {
      return this.data.groupBy;
    },
    bars() {
      return this.data.bars;
    },
  },
  methods: {
    formatDate(isoDateStr) {
      if (isoDateStr) {
        return localeDateFormat.asDate.format(new Date(isoDateStr));
      }
      return '';
    },
  },
  palette: [DATA_VIZ_GREEN_500, DATA_VIZ_MAGENTA_600, DATA_VIZ_BLUE_500],
};
</script>

<template>
  <div class="gl-border gl-border-default gl-p-5">
    <h3 class="gl-heading-4">{{ s__('Pipeline|Status') }}</h3>
    <gl-loading-icon v-if="loading" size="xl" class="gl-mb-5" />
    <gl-stacked-column-chart
      v-else
      x-axis-type="category"
      :x-axis-title="s__('Pipelines|Time')"
      :y-axis-title="s__('Pipelines|Number of Pipelines')"
      :custom-palette="$options.palette"
      :group-by="groupBy"
      :bars="bars"
      :include-legend-avg-max="false"
    >
      <template #tooltip-title="{ params }">
        <template v-if="params">{{ formatDate(params.value) }}</template>
      </template>
    </gl-stacked-column-chart>
  </div>
</template>
