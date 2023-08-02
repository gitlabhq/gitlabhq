<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlSkeletonLoader, GlAlert, GlLoadingIcon } from '@gitlab/ui';

import {
  SKELETON_VARIANTS_BY_ROUTE,
  SKELETON_STATE,
  DEFAULT_TIMERS,
  OBSERVABILITY_ROUTES,
  TIMEOUT_ERROR_LABEL,
  TIMEOUT_ERROR_MESSAGE,
  SKELETON_VARIANT_EMBED,
  SKELETON_SPINNER_VARIANT,
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
    GlLoadingIcon,
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
  computed: {
    skeletonVisible() {
      return this.state === SKELETON_STATE.VISIBLE;
    },
    skeletonHidden() {
      return this.state === SKELETON_STATE.HIDDEN;
    },
    errorVisible() {
      return this.state === SKELETON_STATE.ERROR;
    },
    spinnerVariant() {
      return this.variant === SKELETON_SPINNER_VARIANT;
    },
    embedVariant() {
      return this.variant === SKELETON_VARIANT_EMBED;
    },
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
    onError() {
      clearTimeout(this.errorTimeout);
      clearTimeout(this.loadingTimeout);

      this.showError();
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
    isVariantByRoute(route) {
      return this.variant === SKELETON_VARIANTS_BY_ROUTE[route];
    },
  },
};
</script>
<template>
  <div class="gl-flex-grow-1 gl-display-flex gl-flex-direction-column gl-flex-align-items-stretch">
    <transition name="fade">
      <div v-if="skeletonVisible" class="gl-px-5 gl-my-5">
        <dashboards-skeleton v-if="isVariantByRoute($options.OBSERVABILITY_ROUTES.DASHBOARDS)" />
        <explore-skeleton v-else-if="isVariantByRoute($options.OBSERVABILITY_ROUTES.EXPLORE)" />
        <manage-skeleton v-else-if="isVariantByRoute($options.OBSERVABILITY_ROUTES.MANAGE)" />
        <embed-skeleton v-else-if="embedVariant" />
        <gl-loading-icon v-else-if="spinnerVariant" size="lg" />

        <gl-skeleton-loader v-else>
          <rect y="2" width="10" height="8" />
          <rect y="2" x="15" width="15" height="8" />
          <rect y="2" x="35" width="15" height="8" />
          <rect y="15" width="400" height="30" />
        </gl-skeleton-loader>
      </div>

      <!-- The double condition is only here temporarily for back-compatibility reasons. Will be removed in next iteration https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2275 -->
      <div
        v-else-if="spinnerVariant && skeletonHidden"
        data-testid="content-wrapper"
        class="gl-flex-grow-1 gl-display-flex gl-flex-direction-column gl-flex-align-items-stretch"
      >
        <slot></slot>
      </div>
    </transition>

    <gl-alert
      v-if="errorVisible"
      :title="$options.i18n.TIMEOUT_ERROR_LABEL"
      variant="danger"
      :dismissible="false"
      class="gl-m-5"
    >
      {{ $options.i18n.TIMEOUT_ERROR_MESSAGE }}
    </gl-alert>

    <!-- This is only kept temporarily for back-compatibility reasons. Will be removed in next iteration https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2275 -->
    <transition v-if="!spinnerVariant">
      <div
        v-show="skeletonHidden"
        data-testid="content-wrapper"
        class="gl-flex-grow-1 gl-display-flex gl-flex-direction-column gl-flex-align-items-stretch"
      >
        <slot></slot>
      </div>
    </transition>
  </div>
</template>
