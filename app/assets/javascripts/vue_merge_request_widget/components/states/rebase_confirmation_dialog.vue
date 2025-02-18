<script>
import { GlModal, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'RebaseConfirmationDialog',
  i18n: {
    primary: __('Rebase'),
    cancel: __('Cancel'),
    info: __('This will rebase all commits from the source branch onto the target branch.'),
    title: __('Rebase source branch?'),
  },
  components: {
    GlModal,
    GlButton,
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    hide() {
      this.$refs.modal.hide();
    },
    cancel() {
      this.hide();
      this.$emit('cancel');
    },
    focusCancelButton() {
      this.$refs.cancelButton.$el.focus();
    },
    confirmRebase() {
      this.$emit('rebase-confirmed');
      this.hide();
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    size="sm"
    modal-id="rebase-confirmation-dialog"
    :title="$options.i18n.title"
    :visible="visible"
    data-testid="rebase-confirmation-dialog"
    @shown="focusCancelButton"
    @hide="$emit('cancel')"
  >
    <p>{{ $options.i18n.info }}</p>
    <template #modal-footer>
      <gl-button ref="cancelButton" data-testid="rebase-cancel-btn" @click="cancel">{{
        $options.i18n.cancel
      }}</gl-button>
      <gl-button variant="confirm" data-testid="confirm-rebase" @click="confirmRebase">
        {{ $options.i18n.primary }}
      </gl-button>
    </template>
  </gl-modal>
</template>
