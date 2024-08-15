<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import Tracking from '~/tracking';
import { BUTTON_TOOLTIP_RETRY, BUTTON_TOOLTIP_CANCEL, TRACKING_CATEGORIES } from '~/ci/constants';
import PipelineMultiActions from './pipeline_multi_actions.vue';
import PipelinesManualActions from './pipelines_manual_actions.vue';
import PipelineStopModal from './pipeline_stop_modal.vue';

export default {
  BUTTON_TOOLTIP_RETRY,
  BUTTON_TOOLTIP_CANCEL,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    PipelineMultiActions,
    PipelinesManualActions,
    PipelineStopModal,
  },
  mixins: [Tracking.mixin()],
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isCanceling: false,
      isRetrying: false,
      showConfirmationModal: false,
      pipelineToCancel: this.pipeline,
    };
  },
  computed: {
    hasActions() {
      return (
        this.pipeline?.details?.has_manual_actions || this.pipeline?.details?.has_scheduled_actions
      );
    },
  },
  watch: {
    pipeline() {
      if (this.isCanceling || this.isRetrying) {
        this.isCanceling = false;
        this.isRetrying = false;
      }
    },
  },
  methods: {
    onCloseModal() {
      this.showConfirmationModal = false;
    },
    onConfirmCancelPipeline() {
      this.isCanceling = true;
      this.showConfirmationModal = false;

      this.$emit('cancel-pipeline', this.pipelineToCancel);
    },
    handleCancelClick() {
      this.showConfirmationModal = true;
      this.pipelineToCancel = this.pipeline;

      this.trackClick('click_cancel_button');
    },
    handleRetryClick() {
      this.isRetrying = true;

      this.trackClick('click_retry_button');

      this.$emit('retry-pipeline', this.pipeline);
    },
    trackClick(action) {
      this.track(action, { label: TRACKING_CATEGORIES.table });
    },
  },
};
</script>

<template>
  <div class="gl-text-right">
    <pipeline-stop-modal
      :pipeline="pipelineToCancel"
      :show-confirmation-modal="showConfirmationModal"
      @submit="onConfirmCancelPipeline"
      @close-modal="onCloseModal"
    />

    <div class="btn-group">
      <pipelines-manual-actions
        v-if="hasActions"
        :iid="pipeline.iid"
        @refresh-pipeline-table="$emit('refresh-pipelines-table')"
      />

      <gl-button
        v-if="pipeline.flags.retryable"
        v-gl-tooltip.hover
        :aria-label="$options.BUTTON_TOOLTIP_RETRY"
        :title="$options.BUTTON_TOOLTIP_RETRY"
        :disabled="isRetrying"
        :loading="isRetrying"
        class="js-pipelines-retry-button"
        data-testid="pipelines-retry-button"
        icon="retry"
        variant="default"
        category="secondary"
        @click="handleRetryClick"
      />

      <gl-button
        v-if="pipeline.flags.cancelable"
        v-gl-tooltip.hover
        :aria-label="$options.BUTTON_TOOLTIP_CANCEL"
        :title="$options.BUTTON_TOOLTIP_CANCEL"
        :loading="isCanceling"
        :disabled="isCanceling"
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
