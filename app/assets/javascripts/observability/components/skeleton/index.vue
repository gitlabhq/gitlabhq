<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { SKELETON_VARIANT } from '../../constants';
import DashboardsSkeleton from './dashboards.vue';
import ExploreSkeleton from './explore.vue';
import ManageSkeleton from './manage.vue';

export default {
  SKELETON_VARIANT,
  components: {
    GlSkeletonLoader,
    DashboardsSkeleton,
    ExploreSkeleton,
    ManageSkeleton,
  },
  props: {
    variant: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      loading: null,
      timerId: null,
    };
  },
  mounted() {
    this.timerId = setTimeout(() => {
      /**
       *  If observability UI is not loaded then this.loading would be null
       *  we will show skeleton in that case
       */
      if (this.loading !== false) {
        this.showSkeleton();
      }
    }, 500);
  },
  methods: {
    handleSkeleton() {
      if (this.loading === null) {
        /**
         *  If observability UI content loads with in 500ms
         *  do not show skeleton.
         */
        clearTimeout(this.timerId);
        return;
      }

      /**
       *  If observability UI content loads after 500ms
       *  wait for 400ms to hide skeleton.
       *  This is mostly to avoid the flashing effect If content loads imediately after skeleton
       */
      setTimeout(this.hideSkeleton, 400);
    },
    hideSkeleton() {
      this.loading = false;
    },
    showSkeleton() {
      this.loading = true;
    },
  },
};
</script>
<template>
  <div class="gl-flex-grow-1 gl-display-flex gl-flex-direction-column gl-flex-align-items-stretch">
    <div v-show="loading" class="gl-px-5">
      <dashboards-skeleton v-if="variant === $options.SKELETON_VARIANT.DASHBOARDS" />
      <explore-skeleton v-else-if="variant === $options.SKELETON_VARIANT.EXPLORE" />
      <manage-skeleton v-else-if="variant === $options.SKELETON_VARIANT.MANAGE" />

      <gl-skeleton-loader v-else>
        <rect y="2" width="10" height="8" />
        <rect y="2" x="15" width="15" height="8" />
        <rect y="2" x="35" width="15" height="8" />
        <rect y="15" width="400" height="30" />
      </gl-skeleton-loader>
    </div>

    <div
      v-show="!loading"
      class="gl-flex-grow-1 gl-display-flex gl-flex-direction-column gl-flex-align-items-stretch"
    >
      <slot></slot>
    </div>
  </div>
</template>
