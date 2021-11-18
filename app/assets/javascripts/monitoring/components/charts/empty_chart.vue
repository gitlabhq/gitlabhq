<script>
import chartEmptyStateIllustration from '@gitlab/svgs/dist/illustrations/chart-empty-state.svg';
import { GlSafeHtmlDirective } from '@gitlab/ui';
import { chartHeight } from '../../constants';

export default {
  directives: {
    SafeHtml: GlSafeHtmlDirective,
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
  safeHtmlConfig: { ADD_TAGS: ['use'] },
};
</script>
<template>
  <div class="d-flex flex-column justify-content-center">
    <div
      v-safe-html:[$options.safeHtmlConfig]="chartEmptyStateIllustration"
      class="gl-mt-3 svg-w-100 d-flex align-items-center"
      :style="svgContainerStyle"
    ></div>
    <h5 class="text-center gl-mt-3">{{ __('No data to display') }}</h5>
  </div>
</template>
