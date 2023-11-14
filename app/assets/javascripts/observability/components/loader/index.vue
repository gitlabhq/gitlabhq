<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';

import {
  LOADER_STATE,
  CONTENT_STATE,
  DEFAULT_TIMERS,
  TIMEOUT_ERROR_LABEL,
  TIMEOUT_ERROR_MESSAGE,
} from './constants';

export default {
  components: {
    GlAlert,
    GlLoadingIcon,
  },
  LOADER_STATE,
  i18n: {
    TIMEOUT_ERROR_LABEL,
    TIMEOUT_ERROR_MESSAGE,
  },
  props: {
    contentState: {
      type: String,
      required: false,
      default: null,
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
    loaderVisible() {
      return this.state === LOADER_STATE.VISIBLE;
    },
    loaderHidden() {
      return this.state === LOADER_STATE.HIDDEN;
    },
    errorVisible() {
      return this.state === LOADER_STATE.ERROR;
    },
  },
  watch: {
    contentState(newValue) {
      if (newValue === CONTENT_STATE.LOADED) {
        this.onContentLoaded();
      } else if (newValue === CONTENT_STATE.ERROR) {
        this.onError();
      }
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

      this.hideLoader();
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
         *  show the loader
         */
        if (this.state !== LOADER_STATE.HIDDEN) {
          this.showLoader();
        }
      }, DEFAULT_TIMERS.CONTENT_WAIT_MS);
    },
    setErrorTimeout() {
      this.errorTimeout = setTimeout(() => {
        /**
         *  If content is not loaded within TIMEOUT_MS,
         *  show the error dialog
         */
        if (this.state !== LOADER_STATE.HIDDEN) {
          this.showError();
        }
      }, DEFAULT_TIMERS.TIMEOUT_MS);
    },
    hideLoader() {
      this.state = LOADER_STATE.HIDDEN;
    },
    showLoader() {
      this.state = LOADER_STATE.VISIBLE;
    },
    showError() {
      this.state = LOADER_STATE.ERROR;
    },
  },
};
</script>
<template>
  <div class="gl-flex-grow-1 gl-display-flex gl-flex-direction-column gl-flex-align-items-stretch">
    <transition name="fade">
      <div v-if="loaderVisible" class="gl-px-5 gl-my-5">
        <gl-loading-icon size="lg" />
      </div>

      <div
        v-else-if="loaderHidden"
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
  </div>
</template>
