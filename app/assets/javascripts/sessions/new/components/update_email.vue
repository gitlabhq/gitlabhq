<script>
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import {
  I18N_UPDATE_EMAIL,
  I18N_UPDATE_EMAIL_GUIDANCE,
  I18N_UPDATE_EMAIL_SUCCESS,
  I18N_GENERIC_ERROR,
  SUCCESS_RESPONSE,
  FAILURE_RESPONSE,
} from '../constants';
import EmailForm from './email_form.vue';

export default {
  name: 'UpdateEmail',
  components: { EmailForm },
  inject: ['updateEmailPath'],
  data() {
    return {
      email: '',
      verifyError: '',
    };
  },
  methods: {
    updateEmail(email) {
      this.verifyError = '';
      this.email = email;

      axios
        .patch(this.updateEmailPath, { user: { email } })
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
    updateEmail: I18N_UPDATE_EMAIL,
    guidance: I18N_UPDATE_EMAIL_GUIDANCE,
  },
};
</script>

<template>
  <email-form
    :error="verifyError"
    :form-info="$options.i18n.guidance"
    :submit-text="$options.i18n.updateEmail"
    @submit-email="updateEmail"
    @cancel="() => $emit('verifyToken')"
  />
</template>
