<script>
import { GlModal, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'MergeFailedPipelineConfirmationDialog',
  i18n: {
    primary: __('Merge unverified changes'),
    cancel: __('Cancel'),
    info: __(
      'The latest pipeline for this merge request did not succeed. The latest changes are unverified.',
    ),
    confirmation: __('Are you sure you want to attempt to merge?'),
    title: __('Merge unverified changes?'),
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
    mergeChanges() {
      this.$emit('mergeWithFailedPipeline');
      this.hide();
    },
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    size="sm"
    modal-id="merge-train-failed-pipeline-confirmation-dialog"
    :title="$options.i18n.title"
    :visible="visible"
    data-testid="merge-failed-pipeline-confirmation-dialog"
    @shown="focusCancelButton"
    @hide="$emit('cancel')"
  >
    <p>{{ $options.i18n.info }}</p>
    <p>{{ $options.i18n.confirmation }}</p>
    <template #modal-footer>
      <gl-button ref="cancelButton" data-testid="merge-cancel-btn" @click="cancel">{{
        $options.i18n.cancel
      }}</gl-button>
      <gl-button variant="danger" data-testid="merge-unverified-changes" @click="mergeChanges">
        {{ $options.i18n.primary }}
      </gl-button>
    </template>
  </gl-modal>
</template>
