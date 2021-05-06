<script>
import { GlButton, GlTooltipDirective, GlModalDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import eventHub from '../../event_hub';
import PipelineMultiActions from './pipeline_multi_actions.vue';
import PipelinesManualActions from './pipelines_manual_actions.vue';

export default {
  i18n: {
    cancelTitle: __('Cancel'),
    redeployTitle: __('Retry'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModalDirective,
  },
  components: {
    GlButton,
    PipelineMultiActions,
    PipelinesManualActions,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
    cancelingPipeline: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isRetrying: false,
    };
  },
  computed: {
    actions() {
      if (!this.pipeline || !this.pipeline.details) {
        return [];
      }
      const { details } = this.pipeline;
      return [...(details.manual_actions || []), ...(details.scheduled_actions || [])];
    },
    isCancelling() {
      return this.cancelingPipeline === this.pipeline.id;
    },
  },
  watch: {
    pipeline() {
      this.isRetrying = false;
    },
  },
  methods: {
    handleCancelClick() {
      eventHub.$emit('openConfirmationModal', {
        pipeline: this.pipeline,
        endpoint: this.pipeline.cancel_path,
      });
    },
    handleRetryClick() {
      this.isRetrying = true;
      eventHub.$emit('retryPipeline', this.pipeline.retry_path);
    },
  },
};
</script>

<template>
  <div class="gl-text-right">
    <div class="btn-group">
      <pipelines-manual-actions v-if="actions.length > 0" :actions="actions" />

      <gl-button
        v-if="pipeline.flags.retryable"
        v-gl-tooltip.hover
        :aria-label="$options.i18n.redeployTitle"
        :title="$options.i18n.redeployTitle"
        :disabled="isRetrying"
        :loading="isRetrying"
        class="js-pipelines-retry-button"
        data-qa-selector="pipeline_retry_button"
        icon="repeat"
        variant="default"
        category="secondary"
        @click="handleRetryClick"
      />

      <gl-button
        v-if="pipeline.flags.cancelable"
        v-gl-tooltip.hover
        v-gl-modal-directive="'confirmation-modal'"
        :aria-label="$options.i18n.cancelTitle"
        :title="$options.i18n.cancelTitle"
        :loading="isCancelling"
        :disabled="isCancelling"
        icon="close"
        variant="danger"
        category="primary"
        class="js-pipelines-cancel-button"
        @click="handleCancelClick"
      />

      <pipeline-multi-actions :pipeline-id="pipeline.id" />
    </div>
  </div>
</template>
