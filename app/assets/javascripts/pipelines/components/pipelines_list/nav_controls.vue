<script>
import { GlDeprecatedButton } from '@gitlab/ui';
import LoadingButton from '~/vue_shared/components/loading_button.vue';

export default {
  name: 'PipelineNavControls',
  components: {
    LoadingButton,
    GlDeprecatedButton,
  },
  props: {
    newPipelinePath: {
      type: String,
      required: false,
      default: null,
    },

    resetCachePath: {
      type: String,
      required: false,
      default: null,
    },

    ciLintPath: {
      type: String,
      required: false,
      default: null,
    },

    isResetCacheButtonLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    onClickResetCache() {
      this.$emit('resetRunnersCache', this.resetCachePath);
    },
  },
};
</script>
<template>
  <div class="nav-controls">
    <gl-deprecated-button
      v-if="newPipelinePath"
      :href="newPipelinePath"
      variant="success"
      class="js-run-pipeline"
    >
      {{ s__('Pipelines|Run Pipeline') }}
    </gl-deprecated-button>

    <loading-button
      v-if="resetCachePath"
      :loading="isResetCacheButtonLoading"
      :label="s__('Pipelines|Clear Runner Caches')"
      class="js-clear-cache"
      @click="onClickResetCache"
    />

    <gl-deprecated-button v-if="ciLintPath" :href="ciLintPath" class="js-ci-lint">
      {{ s__('Pipelines|CI Lint') }}
    </gl-deprecated-button>
  </div>
</template>
