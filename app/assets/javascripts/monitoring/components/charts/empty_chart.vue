<script>
import chartEmptyStateIllustration from '@gitlab/svgs/dist/illustrations/chart-empty-state.svg';
import { chartHeight } from '../../constants';

export default {
  props: {
    graphTitle: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      height: chartHeight,
    };
  },
  computed: {
    svgContainerStyle() {
      return {
        height: `${this.height}px`,
      };
    },
  },
  created() {
    this.chartEmptyStateIllustration = chartEmptyStateIllustration;
  },
};
</script>
<template>
  <div class="prometheus-graph col-12 col-lg-6 d-flex flex-column justify-content-center">
    <div class="prometheus-graph-header">
      <h5 ref="graphTitle" class="prometheus-graph-title">{{ graphTitle }}</h5>
    </div>
    <div
      class="prepend-top-8 svg-w-100 d-flex align-items-center"
      :style="svgContainerStyle"
      v-html="chartEmptyStateIllustration"
    ></div>
    <h5 class="text-center prepend-top-8">{{ __('No data to display') }}</h5>
  </div>
</template>
