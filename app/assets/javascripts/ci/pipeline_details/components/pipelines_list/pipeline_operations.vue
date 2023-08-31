<script>
import { GlButton, GlTooltipDirective, GlModalDirective } from '@gitlab/ui';
import Tracking from '~/tracking';
import eventHub from '../../event_hub';
import { BUTTON_TOOLTIP_RETRY, BUTTON_TOOLTIP_CANCEL, TRACKING_CATEGORIES } from '../../constants';
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
  mixins: [Tracking.mixin()],
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
    hasActions() {
      return (
        this.pipeline?.details?.has_manual_actions || this.pipeline?.details?.has_scheduled_actions
      );
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
      this.trackClick('click_cancel_button');
      eventHub.$emit('openConfirmationModal', {
        pipeline: this.pipeline,
        endpoint: this.pipeline.cancel_path,
      });
    },
    handleRetryClick() {
      this.isRetrying = true;
      this.trackClick('click_retry_button');
      eventHub.$emit('retryPipeline', this.pipeline.retry_path);
    },
    trackClick(action) {
      this.track(action, { label: TRACKING_CATEGORIES.table });
    },
  },
};
</script>

<template>
  <div class="gl-text-right">
    <div class="btn-group">
      <pipelines-manual-actions v-if="hasActions" :iid="pipeline.iid" />

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
