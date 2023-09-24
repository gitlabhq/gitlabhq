<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import {
  I18N_BULK_DELETE_MODAL_TITLE,
  I18N_BULK_DELETE_BODY,
  I18N_BULK_DELETE_ACTION,
  I18N_MODAL_CANCEL,
  BULK_DELETE_MODAL_ID,
} from '../constants';

export default {
  name: 'BulkDeleteModal',
  components: {
    GlModal,
    GlSprintf,
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    artifactsToDelete: {
      type: Array,
      required: true,
    },
    isDeleting: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    checkedCount() {
      return this.artifactsToDelete.length || 0;
    },
    modalActionPrimary() {
      return {
        text: I18N_BULK_DELETE_ACTION(this.checkedCount),
        attributes: {
          loading: this.isDeleting,
          variant: 'danger',
        },
      };
    },
    modalActionCancel() {
      return {
        text: I18N_MODAL_CANCEL,
        attributes: {
          disabled: this.isDeleting,
        },
      };
    },
  },
  BULK_DELETE_MODAL_ID,
  i18n: {
    modalTitle: I18N_BULK_DELETE_MODAL_TITLE,
    modalBody: I18N_BULK_DELETE_BODY,
  },
};
</script>
<template>
  <gl-modal
    size="sm"
    :modal-id="$options.BULK_DELETE_MODAL_ID"
    :visible="visible"
    :title="$options.i18n.modalTitle(checkedCount)"
    :action-primary="modalActionPrimary"
    :action-cancel="modalActionCancel"
    data-testid="artifacts-bulk-delete-modal"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <gl-sprintf :message="$options.i18n.modalBody(checkedCount)" />
  </gl-modal>
</template>
