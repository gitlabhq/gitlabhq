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
    queryResult() {
      return this.queryInfo.result[0]?.value[1];
    },
    /**
     * This method formats the query result from a promQL expression
     * allowing a user to format the data in percentile values
     * by using the `max_value` inner property from the graphData prop
     * @returns {(String)}
     */
    statValue() {
      const chartValue = this.graphData?.max_value
        ? (this.queryResult / Number(this.graphData.max_value)) * 100
        : this.queryResult;

      return `${roundOffFloat(chartValue, 1)}${this.queryInfo.unit}`;
    },
    graphTitle() {
      return this.queryInfo.label;
    },
  },
};
</script>
<template>
  <div>
    <gl-single-stat :value="statValue" :title="graphTitle" variant="success" />
  </div>
</template>
