<script>
import { GlSkeletonLoader, GlAlert } from '@gitlab/ui';

import {
  SKELETON_VARIANTS_BY_ROUTE,
  SKELETON_STATE,
  DEFAULT_TIMERS,
  OBSERVABILITY_ROUTES,
  TIMEOUT_ERROR_LABEL,
  TIMEOUT_ERROR_MESSAGE,
  SKELETON_VARIANT_EMBED,
} from '../../constants';
import DashboardsSkeleton from './dashboards.vue';
import ExploreSkeleton from './explore.vue';
import ManageSkeleton from './manage.vue';
import EmbedSkeleton from './embed.vue';

export default {
  components: {
    GlSkeletonLoader,
    DashboardsSkeleton,
    ExploreSkeleton,
    ManageSkeleton,
    EmbedSkeleton,
    GlAlert,
  },
  SKELETON_VARIANTS_BY_ROUTE,
  SKELETON_STATE,
  OBSERVABILITY_ROUTES,
  SKELETON_VARIANT_EMBED,
  i18n: {
    TIMEOUT_ERROR_LABEL,
    TIMEOUT_ERROR_MESSAGE,
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
      state: null,
      loadingTimeout: null,
      errorTimeout: null,
    };
  },
  mounted() {
    this.setLoadingTimeout();
    this.setErrorTimeout();
  },
  destroyed() {
    clearTimeout(this.loadingTimeout);
    clearTimeout(this.errorTimeout);
  },
  methods: {
    onContentLoaded() {
      clearTimeout(this.errorTimeout);
      clearTimeout(this.loadingTimeout);

      this.hideSkeleton();
    },
    setLoadingTimeout() {
      this.loadingTimeout = setTimeout(() => {
        /**
         *  If content is not loaded within CONTENT_WAIT_MS,
         *  show the skeleton
         */
        if (this.state !== SKELETON_STATE.HIDDEN) {
          this.showSkeleton();
        }
      }, DEFAULT_TIMERS.CONTENT_WAIT_MS);
    },
    setErrorTimeout() {
      this.errorTimeout = setTimeout(() => {
        /**
         *  If content is not loaded within TIMEOUT_MS,
         *  show the error dialog
         */
        if (this.state !== SKELETON_STATE.HIDDEN) {
          this.showError();
        }
      }, DEFAULT_TIMERS.TIMEOUT_MS);
    },
    hideSkeleton() {
      this.state = SKELETON_STATE.HIDDEN;
    },
    showSkeleton() {
      this.state = SKELETON_STATE.VISIBLE;
    },
    showError() {
      this.state = SKELETON_STATE.ERROR;
    },

    isSkeletonShown(route) {
      return this.variant === SKELETON_VARIANTS_BY_ROUTE[route];
    },
  },
};
</script>
<template>
  <div class="gl-flex-grow-1 gl-display-flex gl-flex-direction-column gl-flex-align-items-stretch">
    <transition name="fade">
      <div v-if="state === $options.SKELETON_STATE.VISIBLE" class="gl-px-5">
        <dashboards-skeleton v-if="isSkeletonShown($options.OBSERVABILITY_ROUTES.DASHBOARDS)" />
        <explore-skeleton v-else-if="isSkeletonShown($options.OBSERVABILITY_ROUTES.EXPLORE)" />
        <manage-skeleton v-else-if="isSkeletonShown($options.OBSERVABILITY_ROUTES.MANAGE)" />
        <embed-skeleton v-else-if="variant === $options.SKELETON_VARIANT_EMBED" />

        <gl-skeleton-loader v-else>
          <rect y="2" width="10" height="8" />
          <rect y="2" x="15" width="15" height="8" />
          <rect y="2" x="35" width="15" height="8" />
          <rect y="15" width="400" height="30" />
        </gl-skeleton-loader>
      </div>
    </transition>

    <gl-alert
      v-if="state === $options.SKELETON_STATE.ERROR"
      :title="$options.i18n.TIMEOUT_ERROR_LABEL"
      variant="danger"
      :dismissible="false"
      class="gl-m-5"
    >
      {{ $options.i18n.TIMEOUT_ERROR_MESSAGE }}
    </gl-alert>

    <transition>
      <div
        v-show="state === $options.SKELETON_STATE.HIDDEN"
        data-testid="observability-wrapper"
        class="gl-flex-grow-1 gl-display-flex gl-flex-direction-column gl-flex-align-items-stretch"
      >
        <slot></slot>
      </div>
    </transition>
  </div>
</template>
