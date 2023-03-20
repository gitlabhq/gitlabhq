<script>
import { GlModal } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  modalId: 'pipeline-take-ownership-modal',
  i18n: {
    takeOwnership: s__('PipelineSchedules|Take ownership'),
    ownershipMessage: s__(
      'PipelineSchedules|Only the owner of a pipeline schedule can make changes to it. Do you want to take ownership of this schedule?',
    ),
    cancelLabel: __('Cancel'),
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
  computed: {
    actionCancel() {
      return { text: this.$options.i18n.cancelLabel };
    },
    actionPrimary() {
      return {
        text: this.$options.i18n.takeOwnership,
        attributes: {
          variant: 'confirm',
          category: 'primary',
        },
      };
    },
  },
};
</script>
<template>
  <gl-modal
    :visible="visible"
    :modal-id="$options.modalId"
    :action-primary="actionPrimary"
    :action-cancel="actionCancel"
    :title="$options.i18n.takeOwnership"
    size="sm"
    @primary="$emit('takeOwnership')"
    @hide="$emit('hideModal')"
  >
    <p>{{ $options.i18n.ownershipMessage }}</p>
  </gl-modal>
</template>
