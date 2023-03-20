<script>
import { GlModal } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  components: {
    GlModal,
  },
  props: {
    ownershipUrl: {
      type: String,
      required: true,
    },
  },
  modalId: 'pipeline-take-ownership-modal',
  i18n: {
    takeOwnership: s__('PipelineSchedules|Take ownership'),
    ownershipMessage: s__(
      'PipelineSchedules|Only the owner of a pipeline schedule can make changes to it. Do you want to take ownership of this schedule?',
    ),
    cancelLabel: __('Cancel'),
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
          href: this.ownershipUrl,
          'data-method': 'post',
        },
      };
    },
  },
};
</script>
<template>
  <gl-modal
    :modal-id="$options.modalId"
    :action-primary="actionPrimary"
    :action-cancel="actionCancel"
    :title="$options.i18n.takeOwnership"
  >
    <p>{{ $options.i18n.ownershipMessage }}</p>
  </gl-modal>
</template>
