<script>
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { roundOffFloat } from '~/lib/utils/common_utils';
import { graphDataValidatorForValues } from '../../utils';

export default {
  components: {
    GlSingleStat,
  },
  inheritAttrs: false,
  props: {
    graphData: {
      type: Object,
      required: true,
      validator: graphDataValidatorForValues.bind(null, true),
    },
  },
  computed: {
    queryInfo() {
      return this.graphData.metrics[0];
    },
    engineeringNotation() {
      return `${roundOffFloat(this.queryInfo.result[0].value[1], 1)}${this.queryInfo.unit}`;
    },
    graphTitle() {
      return this.queryInfo.label;
    },
  },
};
</script>
<template>
  <div class="prometheus-graph">
    <div class="prometheus-graph-header">
      <h5 ref="graphTitle" class="prometheus-graph-title">{{ graphTitle }}</h5>
    </div>
    <gl-single-stat :value="engineeringNotation" :title="graphTitle" variant="success" />
  </div>
</template>
