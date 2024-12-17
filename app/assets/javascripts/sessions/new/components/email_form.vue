<script>
import { GlForm, GlFormGroup, GlFormInput, GlButton } from '@gitlab/ui';
import { isUserEmail } from '~/lib/utils/forms';
import { I18N_EMAIL, I18N_CANCEL, I18N_EMAIL_INVALID } from '../constants';

export default {
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlButton,
  },
  props: {
    error: {
      type: String,
      required: false,
      default: '',
    },
    formInfo: {
      type: String,
      required: false,
      default: undefined,
    },
    submitText: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      email: '',
      submitted: false,
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

      return this.error;
    },
  },
  watch: {
    email() {
      this.submitted = false;
    },
  },
  methods: {
    submit() {
      this.submitted = true;
      this.$emit('submit-email', this.email);
    },
  },
  i18n: {
    email: I18N_EMAIL,
    cancel: I18N_CANCEL,
  },
};
</script>

<template>
  <gl-form @submit.prevent="submit">
    <gl-form-group
      :label="$options.i18n.email"
      label-for="email-input"
      :state="inputValidation.state"
      :invalid-feedback="inputValidation.message"
    >
      <gl-form-input
        id="email-input"
        v-model="email"
        type="email"
        autofocus
        :state="inputValidation.state"
      />
      <p v-if="formInfo" class="gl-mt-3 gl-text-subtle">{{ formInfo }}</p>
    </gl-form-group>
    <section class="gl-mt-5">
      <gl-button block variant="confirm" type="submit" :disabled="!inputValidation.state">{{
        submitText
      }}</gl-button>
      <gl-button block variant="link" class="gl-mt-3 gl-h-7" @click="$emit('cancel')">{{
        $options.i18n.cancel
      }}</gl-button>
    </section>
  </gl-form>
</template>
