<script>
import { GlResizeObserverDirective } from '@gitlab/ui';
import { GlGaugeChart } from '@gitlab/ui/dist/charts';
import { isFinite, isArray, isInteger } from 'lodash';
import { graphDataValidatorForValues } from '../../utils';
import { getValidThresholds } from './options';
import { getFormatter, SUPPORTED_FORMATS } from '~/lib/utils/unit_format';

export default {
  components: {
    GlGaugeChart,
  },
  directives: {
    GlResizeObserverDirective,
  },
  props: {
    graphData: {
      type: Object,
      required: true,
      validator: graphDataValidatorForValues.bind(null, true),
    },
  },
  data() {
    return {
      width: 0,
    };
  },
  computed: {
    rangeValues() {
      let min = 0;
      let max = 100;

      const { minValue, maxValue } = this.graphData;

      const isValidMinMax = () => {
        return isFinite(minValue) && isFinite(maxValue) && minValue < maxValue;
      };

      if (isValidMinMax()) {
        min = minValue;
        max = maxValue;
      }

      return {
        min,
        max,
      };
    },
    validThresholds() {
      const { mode, values } = this.graphData?.thresholds || {};
      const range = this.rangeValues;

      if (!isArray(values)) {
        return [];
      }

      return getValidThresholds({ mode, range, values });
    },
    queryResult() {
      return this.graphData?.metrics[0]?.result[0]?.value[1];
    },
    splitValue() {
      const { split } = this.graphData;
      const defaultValue = 10;

      return isInteger(split) && split > 0 ? split : defaultValue;
    },
    textValue() {
      const formatFromPanel = this.graphData.format;
      const defaultFormat = SUPPORTED_FORMATS.engineering;
      const format = SUPPORTED_FORMATS[formatFromPanel] ?? defaultFormat;
      const { queryResult } = this;

      const formatter = getFormatter(format);

      return isFinite(queryResult) ? formatter(queryResult) : '--';
    },
    thresholdsValue() {
      /**
       * If there are no valid thresholds, a default threshold
       * will be set at 90% of the gauge arcs' max value
       */
      const { min, max } = this.rangeValues;

      const defaultThresholdValue = [(max - min) * 0.95];
      return this.validThresholds.length ? this.validThresholds : defaultThresholdValue;
    },
    value() {
      /**
       * The gauge chart gitlab-ui component expects a value
       * of type number.
       *
       * So, if the query result is undefined,
       * we pass the gauge chart a value of NaN.
       */
      return this.queryResult || NaN;
    },
  },
  methods: {
    onResize() {
      if (!this.$refs.gaugeChart) return;
      const { width } = this.$refs.gaugeChart.$el.getBoundingClientRect();
      this.width = width;
    },
  },
};
</script>
<template>
  <div v-gl-resize-observer-directive="onResize">
    <gl-gauge-chart
      ref="gaugeChart"
      v-bind="$attrs"
      :value="value"
      :min="rangeValues.min"
      :max="rangeValues.max"
      :thresholds="thresholdsValue"
      :text="textValue"
      :split-number="splitValue"
      :width="width"
    />
  </div>
</template>
