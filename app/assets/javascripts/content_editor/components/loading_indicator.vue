<script>
import { GlLoadingIcon } from '@gitlab/ui';
import EditorStateObserver from './editor_state_observer.vue';

export default {
  components: {
    GlLoadingIcon,
    EditorStateObserver,
  },
  data() {
    return {
      isLoading: false,
    };
  },
  methods: {
    displayLoadingIndicator() {
      this.isLoading = true;
    },
    hideLoadingIndicator() {
      this.isLoading = false;
    },
  },
};
</script>
<template>
  <editor-state-observer
    @loading="displayLoadingIndicator"
    @loadingSuccess="hideLoadingIndicator"
    @loadingError="hideLoadingIndicator"
  >
    <div
      v-if="isLoading"
      class="gl-w-full gl-display-flex gl-justify-content-center gl-align-items-center gl-absolute gl-top-0 gl-bottom-0"
    >
      <div class="gl-bg-white gl-absolute gl-w-full gl-h-full gl-opacity-3"></div>
      <gl-loading-icon size="md" />
    </div>
  </editor-state-observer>
</template>
