<script>
import { mapState } from 'pinia';
import StickyViewportFillerHeight from '~/diffs/components/sticky_viewport_filler_height.vue';
import { useBatchComments } from '~/batch_comments/store';

export default {
  name: 'FileBrowserHeight',
  components: { StickyViewportFillerHeight },
  props: {
    enableStickyHeight: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      minHeight: 0,
      bottomPadding: 0,
      stickyTopOffset: 0,
      reviewBarCachedHeight: 0,
    };
  },
  computed: {
    ...mapState(useBatchComments, ['draftsCount']),
    reviewBarEnabled() {
      return this.draftsCount > 0;
    },
    stickyBottomOffset() {
      return this.reviewBarEnabled
        ? this.bottomPadding + this.reviewBarCachedHeight
        : this.bottomPadding;
    },
  },
  mounted() {
    const styles = getComputedStyle(this.$el);
    this.stickyTopOffset = parseInt(styles.getPropertyValue('top'), 10);
    this.minHeight = parseInt(styles.getPropertyValue('--file-tree-min-height'), 10);
    this.bottomPadding = parseInt(styles.getPropertyValue('--file-tree-bottom-padding'), 10);
  },
};
</script>

<template>
  <sticky-viewport-filler-height
    v-if="enableStickyHeight"
    ref="root"
    :min-height="minHeight"
    :sticky-top-offset="stickyTopOffset"
    :sticky-bottom-offset="stickyBottomOffset"
  >
    <slot></slot>
  </sticky-viewport-filler-height>
  <div v-else>
    <slot></slot>
  </div>
</template>
