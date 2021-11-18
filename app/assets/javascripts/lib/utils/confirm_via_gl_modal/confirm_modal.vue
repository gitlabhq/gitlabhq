<script>
import { GlModal } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  cancelAction: { text: __('Cancel') },
  components: {
    GlModal,
  },
  props: {
    primaryText: {
      type: String,
      required: false,
      default: __('OK'),
    },
    primaryVariant: {
      type: String,
      required: false,
      default: 'confirm',
    },
  },
  computed: {
    primaryAction() {
      return { text: this.primaryText, attributes: { variant: this.primaryVariant } };
    },
  },
  mounted() {
    this.$refs.modal.show();
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    size="sm"
    modal-id="confirmationModal"
    body-class="gl-display-flex"
    :action-primary="primaryAction"
    :action-cancel="$options.cancelAction"
    hide-header
    @primary="$emit('confirmed')"
    @hidden="$emit('closed')"
  >
    <div class="gl-align-self-center"><slot></slot></div>
  </gl-modal>
</template>
