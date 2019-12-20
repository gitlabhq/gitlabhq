<script>
import $ from 'jquery';
import { debounceByAnimationFrame } from '~/lib/utils/common_utils';

export default {
  data() {
    return {
      width: 0,
      height: 0,
    };
  },
  beforeDestroy() {
    this.contentResizeHandler.off('content.resize', this.debouncedResize);
    window.removeEventListener('resize', this.debouncedResize);
  },
  created() {
    this.debouncedResize = debounceByAnimationFrame(this.onResize);

    // Handle when we explicictly trigger a custom resize event
    this.contentResizeHandler = $(document).on('content.resize', this.debouncedResize);

    // Handle window resize
    window.addEventListener('resize', this.debouncedResize);
  },
  methods: {
    onResize() {
      // Slot dimensions
      const { clientWidth, clientHeight } = this.$refs.chartWrapper;
      this.width = clientWidth;
      this.height = clientHeight;
    },
  },
};
</script>

<template>
  <div ref="chartWrapper">
    <slot :width="width" :height="height"> </slot>
  </div>
</template>
