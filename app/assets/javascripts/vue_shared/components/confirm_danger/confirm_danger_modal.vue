<script>
import { GlModal, GlFormGroup, GlFormInput, GlSprintf } from '@gitlab/ui';
import {
  CONFIRM_DANGER_MODAL_BUTTON,
  CONFIRM_DANGER_MODAL_TITLE,
  CONFIRM_DANGER_PHRASE_TEXT,
  CONFIRM_DANGER_WARNING,
} from './constants';

export default {
  name: 'ConfirmDangerModal',
  components: {
    GlModal,
    GlFormGroup,
    GlFormInput,
    GlSprintf,
  },
  inject: {
    confirmDangerMessage: {
      default: '',
    },
    confirmButtonText: {
      default: CONFIRM_DANGER_MODAL_BUTTON,
    },
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    phrase: {
      type: String,
      required: true,
    },
  },
  data() {
    return { confirmationPhrase: '' };
  },
  computed: {
    isValid() {
      return (
        this.confirmationPhrase.length && this.equalString(this.confirmationPhrase, this.phrase)
      );
    },
    actionPrimary() {
      return {
        text: this.confirmButtonText,
        attributes: [{ variant: 'danger', disabled: !this.isValid }],
      };
    },
  },
  methods: {
    equalString(a, b) {
      return a.trim().toLowerCase() === b.trim().toLowerCase();
    },
  },
  i18n: {
    CONFIRM_DANGER_MODAL_BUTTON,
    CONFIRM_DANGER_MODAL_TITLE,
    CONFIRM_DANGER_WARNING,
    CONFIRM_DANGER_PHRASE_TEXT,
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    :data-testid="modalId"
    :title="$options.i18n.CONFIRM_DANGER_MODAL_TITLE"
    :action-primary="actionPrimary"
    @primary="$emit('confirm')"
  >
    <p v-if="confirmDangerMessage" class="text-danger" data-testid="confirm-danger-message">
      {{ confirmDangerMessage }}
    </p>
    <p data-testid="confirm-danger-warning">{{ $options.i18n.CONFIRM_DANGER_WARNING }}</p>
    <p data-testid="confirm-danger-phrase">
      <gl-sprintf :message="$options.i18n.CONFIRM_DANGER_PHRASE_TEXT">
        <template #phrase_code>
          <code>{{ phrase }}</code>
        </template>
      </gl-sprintf>
    </p>
    <gl-form-group class="form-control" :state="isValid">
      <gl-form-input v-model="confirmationPhrase" data-testid="confirm-danger-input" type="text" />
    </gl-form-group>
  </gl-modal>
</template>
