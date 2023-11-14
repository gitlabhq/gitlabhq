<script>
import { GlForm, GlFormGroup, GlFormInput, GlButton } from '@gitlab/ui';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import { isUserEmail } from '~/lib/utils/forms';
import axios from '~/lib/utils/axios_utils';
import {
  I18N_EMAIL,
  I18N_UPDATE_EMAIL,
  I18N_UPDATE_EMAIL_GUIDANCE,
  I18N_CANCEL,
  I18N_EMAIL_INVALID,
  I18N_UPDATE_EMAIL_SUCCESS,
  I18N_GENERIC_ERROR,
  SUCCESS_RESPONSE,
  FAILURE_RESPONSE,
} from '../constants';

export default {
  name: 'UpdateEmail',
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlButton,
  },
  props: {
    updateEmailPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      email: '',
      submitted: false,
      verifyError: '',
    };
  },
  computed: {
    inputValidation() {
      return {
        state: !(this.submitted && this.invalidFeedback),
        message: this.invalidFeedback,
      };
    },
    invalidFeedback() {
      if (!this.submitted) {
        return '';
      }

      if (!isUserEmail(this.email)) {
        return I18N_EMAIL_INVALID;
      }

      return this.verifyError;
    },
  },
  watch: {
    email() {
      this.verifyError = '';
    },
  },
  methods: {
    updateEmail() {
      this.submitted = true;

      if (!this.inputValidation.state) return;

      axios
        .patch(this.updateEmailPath, { user: { email: this.email } })
        .then(this.handleResponse)
        .catch(this.handleError);
    },
    handleResponse(response) {
      if (response.data.status === undefined) {
        this.handleError();
      } else if (response.data.status === SUCCESS_RESPONSE) {
        this.handleSuccess();
      } else if (response.data.status === FAILURE_RESPONSE) {
        this.verifyError = response.data.message;
      }
    },
    handleSuccess() {
      createAlert({
        message: I18N_UPDATE_EMAIL_SUCCESS,
        variant: VARIANT_SUCCESS,
      });
      this.$emit('verifyToken', this.email);
    },
    handleError(error) {
      createAlert({
        message: I18N_GENERIC_ERROR,
        captureError: true,
        error,
      });
    },
  },
  i18n: {
    email: I18N_EMAIL,
    updateEmail: I18N_UPDATE_EMAIL,
    cancel: I18N_CANCEL,
    guidance: I18N_UPDATE_EMAIL_GUIDANCE,
  },
};
</script>

<template>
  <gl-form novalidate @submit.prevent="updateEmail">
    <gl-form-group
      :label="$options.i18n.email"
      label-for="update-email"
      :state="inputValidation.state"
      :invalid-feedback="inputValidation.message"
    >
      <gl-form-input
        id="update-email"
        v-model="email"
        type="email"
        autofocus
        :state="inputValidation.state"
      />
      <p class="gl-mt-3 gl-text-secondary">{{ $options.i18n.guidance }}</p>
    </gl-form-group>
    <section class="gl-mt-5">
      <gl-button block variant="confirm" type="submit" :disabled="!inputValidation.state">{{
        $options.i18n.updateEmail
      }}</gl-button>
      <gl-button block variant="link" class="gl-mt-3 gl-h-7" @click="$emit('verifyToken')">{{
        $options.i18n.cancel
      }}</gl-button>
    </section>
  </gl-form>
</template>
