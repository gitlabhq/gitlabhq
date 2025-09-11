<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  name: 'LoadingStateListItem',
  components: {
    GlSkeletonLoader,
  },
  props: {
    leftLinesCount: {
      type: Number,
      required: false,
      default: 2,
    },
    rightLinesCount: {
      type: Number,
      required: false,
      default: 2,
    },
  },
};
</script>

<template>
  <div ref="loadingStateListItem" class="gl-flex gl-justify-between">
    <gl-skeleton-loader
      v-if="leftLinesCount > 0"
      :lines="leftLinesCount"
      data-testid="loading-state-list-item-left-skeleton"
    />
    <gl-skeleton-loader
      v-if="rightLinesCount > 0"
      :lines="rightLinesCount"
      :width="100"
      :equal-width-lines="true"
      class="gl-hidden @sm/panel:gl-block"
      data-testid="loading-state-list-item-right-skeleton"
    />
  </div>
</template>
