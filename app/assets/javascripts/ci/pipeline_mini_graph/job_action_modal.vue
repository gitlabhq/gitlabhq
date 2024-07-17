<script>
import { GlModal } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';

export default {
  name: 'JobActionModal',
  i18n: {
    title: s__('PipelineGraph|Are you sure you want to run %{jobName}?'),
    confirmationText: s__('PipelineGraph|Do you want to continue?'),
    actionCancel: { text: __('Cancel') },
  },
  components: {
    GlModal,
  },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    customMessage: {
      type: String,
      required: true,
    },
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
    jobName: {
      type: String,
      required: true,
    },
  },
  computed: {
    modalText() {
      return {
        confirmButton: {
          text: sprintf(__('Yes, run %{jobName}'), {
            jobName: this.jobName,
          }),
        },
        message: sprintf(__('Custom confirmation message: %{message}'), {
          message: this.customMessage,
        }),
        title: sprintf(this.$options.i18n.title, {
          jobName: this.jobName,
        }),
      };
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="job-action-modal"
    :action-cancel="$options.i18n.actionCancel"
    :action-primary="modalText.confirmButton"
    :title="modalText.title"
    :visible="visible"
    @primary="$emit('confirm')"
    @change="$emit('change', $event)"
  >
    <div>
      <p>{{ modalText.message }}</p>
      <span>{{ $options.i18n.confirmationText }}</span>
    </div>
  </gl-modal>
</template>
