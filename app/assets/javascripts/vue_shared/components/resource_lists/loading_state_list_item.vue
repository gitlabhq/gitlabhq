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
  mounted() {
    // We have to manually add the classes after the component is mounted
    // because GlSkeletonLoader does not inherit attributes.
    // https://gitlab.com/gitlab-org/gitlab-services/design.gitlab.com/-/issues/2939
    this.$refs.loadingStateListItem?.children?.[1]?.classList.add('gl-hidden', 'sm:gl-block');
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
      data-testid="loading-state-list-item-right-skeleton"
    />
  </div>
</template>
