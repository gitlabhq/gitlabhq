<script>
import { GlButton, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import { CANCEL_JOBS_MODAL_ID, CANCEL_JOBS_BUTTON_TEXT, CANCEL_BUTTON_TOOLTIP } from '../constants';
import CancelJobsModal from './cancel_jobs_modal.vue';

export default {
  name: 'CancelJobs',
  components: {
    GlButton,
    CancelJobsModal,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  props: {
    url: {
      type: String,
      required: true,
    },
  },
  modalId: CANCEL_JOBS_MODAL_ID,
  buttonText: CANCEL_JOBS_BUTTON_TEXT,
  buttonTooltip: CANCEL_BUTTON_TOOLTIP,
};
</script>
<template>
  <div>
    <gl-button
      v-gl-modal="$options.modalId"
      v-gl-tooltip="$options.buttonTooltip"
      variant="danger"
      >{{ $options.buttonText }}</gl-button
    >
    <cancel-jobs-modal :modal-id="$options.modalId" :url="url" @confirm="$emit('confirm')" />
  </div>
</template>
