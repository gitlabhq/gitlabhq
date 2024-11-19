<script>
import { GlButton, GlLink } from '@gitlab/ui';

export default {
  name: 'PipelineNavControls',
  components: {
    GlButton,
    GlLink,
  },
  inject: ['pipelinesAnalyticsPath'],
  props: {
    isResetCacheButtonLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
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
    <gl-link
      v-if="pipelinesAnalyticsPath"
      class="gl-mb-3 gl-block gl-whitespace-nowrap gl-text-center md:gl-mb-0 md:gl-mr-3"
      :href="pipelinesAnalyticsPath"
      data-testid="view-analytics-link"
    >
      {{ s__('Pipelines|View analytics') }}
    </gl-link>

    <gl-button
      v-if="resetCachePath"
      :loading="isResetCacheButtonLoading"
      class="js-clear-cache"
      data-testid="clear-cache-button"
      @click="onClickResetCache"
    >
      {{ s__('Pipelines|Clear runner caches') }}
    </gl-button>

    <gl-button
      v-if="newPipelinePath"
      :href="newPipelinePath"
      variant="confirm"
      category="primary"
      class="js-run-pipeline"
      data-testid="run-pipeline-button"
    >
      {{ s__('Pipeline|New pipeline') }}
    </gl-button>
  </div>
</template>
