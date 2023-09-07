<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'PipelineNavControls',
  components: {
    GlButton,
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
    <gl-button
      v-if="resetCachePath"
      :loading="isResetCacheButtonLoading"
      class="js-clear-cache"
      data-testid="clear-cache-button"
      @click="onClickResetCache"
    >
      {{ s__('Pipelines|Clear runner caches') }}
    </gl-button>

    <gl-button v-if="ciLintPath" :href="ciLintPath" class="js-ci-lint" data-testid="ci-lint-button">
      {{ s__('Pipelines|CI lint') }}
    </gl-button>

    <gl-button
      v-if="newPipelinePath"
      :href="newPipelinePath"
      variant="confirm"
      category="primary"
      class="js-run-pipeline"
      data-testid="run-pipeline-button"
      data-qa-selector="run_pipeline_button"
    >
      {{ s__('Pipeline|Run pipeline') }}
    </gl-button>
  </div>
</template>
