<script>
import { GlButton, GlModal, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import { BUTTON_TOOLTIP_CANCEL, BUTTON_TOOLTIP_DELETE, BUTTON_TOOLTIP_RETRY } from '~/ci/constants';
import { __ } from '~/locale';
import { DELETE_MODAL_ID } from '../constants';

export default {
  name: 'HeaderActions',
  BUTTON_TOOLTIP_CANCEL,
  BUTTON_TOOLTIP_DELETE,
  BUTTON_TOOLTIP_RETRY,
  modal: {
    id: DELETE_MODAL_ID,
    actionPrimary: {
      text: __('Delete pipeline'),
      attributes: {
        variant: 'danger',
      },
    },
    actionCancel: {
      text: __('Cancel'),
    },
  },
  components: {
    GlButton,
    GlModal,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
    isRetrying: {
      type: Boolean,
      required: true,
    },
    isDeleting: {
      type: Boolean,
      required: true,
    },
    isCanceling: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    canRetryPipeline() {
      const { retryable, userPermissions } = this.pipeline;

      return retryable && userPermissions.updatePipeline;
    },
    canCancelPipeline() {
      const { cancelable, userPermissions } = this.pipeline;

      return cancelable && userPermissions.cancelPipeline;
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-mt-5 gl-flex gl-items-start gl-gap-3 lg:gl-mt-0">
      <gl-button
        v-if="canRetryPipeline"
        v-gl-tooltip
        :aria-label="$options.BUTTON_TOOLTIP_RETRY"
        :title="$options.BUTTON_TOOLTIP_RETRY"
        :loading="isRetrying"
        :disabled="isRetrying"
        variant="confirm"
        data-testid="retry-pipeline"
        @click="$emit('retryPipeline', pipeline.id)"
      >
        {{ __('Retry') }}
      </gl-button>

      <gl-button
        v-if="canCancelPipeline"
        v-gl-tooltip
        :aria-label="$options.BUTTON_TOOLTIP_CANCEL"
        :title="$options.BUTTON_TOOLTIP_CANCEL"
        :loading="isCanceling"
        :disabled="isCanceling"
        variant="danger"
        data-testid="cancel-pipeline"
        @click="$emit('cancelPipeline', pipeline.id)"
      >
        {{ __('Cancel pipeline') }}
      </gl-button>

      <gl-button
        v-if="pipeline.userPermissions.destroyPipeline"
        v-gl-tooltip
        v-gl-modal="$options.modal.id"
        :aria-label="$options.BUTTON_TOOLTIP_DELETE"
        :title="$options.BUTTON_TOOLTIP_DELETE"
        :loading="isDeleting"
        :disabled="isDeleting"
        variant="danger"
        category="secondary"
        data-testid="delete-pipeline"
      >
        {{ __('Delete') }}
      </gl-button>
    </div>

    <gl-modal
      :modal-id="$options.modal.id"
      :title="__('Delete pipeline')"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      @primary="$emit('deletePipeline', pipeline.id)"
    >
      <p>
        {{
          __(
            'Are you sure you want to delete this pipeline? Doing so will expire all pipeline caches and delete all related objects, such as builds, logs, artifacts, and triggers. This action cannot be undone.',
          )
        }}
      </p>
    </gl-modal>
  </div>
</template>
