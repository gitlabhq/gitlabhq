<script>
import { GlButton, GlTooltipDirective, GlModalDirective } from '@gitlab/ui';
import eventHub from '../../event_hub';
import { BUTTON_TOOLTIP_RETRY, BUTTON_TOOLTIP_CANCEL } from '../../constants';
import PipelineMultiActions from './pipeline_multi_actions.vue';
import PipelinesManualActions from './pipelines_manual_actions.vue';

export default {
  BUTTON_TOOLTIP_RETRY,
  BUTTON_TOOLTIP_CANCEL,
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
        :aria-label="$options.BUTTON_TOOLTIP_RETRY"
        :title="$options.BUTTON_TOOLTIP_RETRY"
        :disabled="isRetrying"
        :loading="isRetrying"
        class="js-pipelines-retry-button"
        data-qa-selector="pipeline_retry_button"
        data-testid="pipelines-retry-button"
        icon="retry"
        variant="default"
        category="secondary"
        @click="handleRetryClick"
      />

      <gl-button
        v-if="pipeline.flags.cancelable"
        v-gl-tooltip.hover
        v-gl-modal-directive="'confirmation-modal'"
        :aria-label="$options.BUTTON_TOOLTIP_CANCEL"
        :title="$options.BUTTON_TOOLTIP_CANCEL"
        :loading="isCancelling"
        :disabled="isCancelling"
        icon="cancel"
        variant="danger"
        category="primary"
        class="js-pipelines-cancel-button gl-ml-1"
        data-testid="pipelines-cancel-button"
        @click="handleCancelClick"
      />

      <pipeline-multi-actions :pipeline-id="pipeline.id" />
    </div>
  </div>
</template>
