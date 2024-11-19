<script>
import { GlModal } from '@gitlab/ui';
import { s__, __ } from '~/locale';

export default {
  modal: {
    id: 'delete-pipeline-schedule-modal',
    deleteConfirmation: s__(
      'PipelineSchedules|Are you sure you want to delete this scheduled pipeline?',
    ),
    actionPrimary: {
      text: s__('PipelineSchedules|Delete scheduled pipeline'),
      attributes: { variant: 'danger' },
    },
    actionCancel: {
      text: __('Cancel'),
      attributes: {},
    },
  },
  components: {
    GlModal,
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <gl-modal
    :visible="visible"
    :title="$options.modal.actionPrimary.text"
    :modal-id="$options.modal.id"
    :action-primary="$options.modal.actionPrimary"
    :action-cancel="$options.modal.actionCancel"
    size="sm"
    @primary="$emit('deleteSchedule')"
    @hide="$emit('hideModal')"
  >
    {{ $options.modal.deleteConfirmation }}
  </gl-modal>
</template>
