<script>
import { GlModal } from '@gitlab/ui';

import {
  I18N_MODAL_TITLE,
  I18N_MODAL_BODY,
  I18N_MODAL_PRIMARY,
  I18N_MODAL_CANCEL,
} from '../constants';

export default {
  components: {
    GlModal,
  },
  props: {
    artifactName: {
      type: String,
      required: true,
    },
    deleteInProgress: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    actionPrimary() {
      return {
        text: I18N_MODAL_PRIMARY,
        attributes: { variant: 'danger', loading: this.deleteInProgress },
      };
    },
  },
  actionCancel: { text: I18N_MODAL_CANCEL },
  i18n: {
    title: I18N_MODAL_TITLE,
    body: I18N_MODAL_BODY,
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    modal-id="artifact-delete-modal"
    size="sm"
    :title="$options.i18n.title(artifactName)"
    :action-primary="actionPrimary"
    :action-cancel="$options.actionCancel"
    v-bind="$attrs"
    v-on="$listeners"
  >
    {{ $options.i18n.body }}
  </gl-modal>
</template>
