<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormInput, GlFormTextarea } from '@gitlab/ui';
import { createAdminSshCertificate } from '~/api/admin_ssh_certificates_api';
import { HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import { __, s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

const VALIDATION_PREFIX = 'Validation failed: ';

// Mirror the API param limits so oversized input never reaches the 400 path.
const TITLE_MAX_LENGTH = 255;
const KEY_MAX_LENGTH = 5000;

export default {
  name: 'AddCertificateAuthorityForm',
  components: { GlAlert, GlButton, GlForm, GlFormGroup, GlFormInput, GlFormTextarea },
  emits: ['added', 'cancel'],
  data() {
    return {
      title: '',
      key: '',
      submitted: false,
      serverKeyError: '',
      hasUnexpectedError: false,
      isSaving: false,
    };
  },
  computed: {
    titleError() {
      return this.title.trim() ? '' : this.$options.i18n.titleRequired;
    },
    keyError() {
      return this.key.trim() ? this.serverKeyError : this.$options.i18n.keyRequired;
    },
    isValid() {
      return !this.titleError && !this.keyError;
    },
  },
  watch: {
    key() {
      this.serverKeyError = '';
    },
  },
  methods: {
    fieldState(error) {
      return this.submitted && error ? false : null;
    },
    async onSubmit() {
      this.submitted = true;
      this.serverKeyError = '';
      this.hasUnexpectedError = false;

      if (!this.isValid) return;

      this.isSaving = true;

      try {
        await createAdminSshCertificate({ title: this.title.trim(), key: this.key.trim() });
        this.$emit('added');
      } catch (error) {
        const { status, data } = error.response ?? {};

        if (status === HTTP_STATUS_UNPROCESSABLE_ENTITY && data?.message) {
          this.serverKeyError = data.message.replace(VALIDATION_PREFIX, '');
        } else {
          Sentry.captureException(error);
          this.hasUnexpectedError = true;
        }
      } finally {
        this.isSaving = false;
      }
    },
  },
  i18n: {
    titleLabel: __('Title'),
    titleDescription: s__('SshCertificates|Key titles are publicly visible.'),
    titleRequired: s__('SshCertificates|Title is required.'),
    keyLabel: s__('SshCertificates|Public key'),
    keyDescription: s__(
      "SshCertificates|This is the CA's public key, not an individual user's key. Certificates it signs are trusted instance-wide.",
    ),
    keyRequired: s__('SshCertificates|Public key is required.'),
    submit: s__('SshCertificates|Add certificate authority'),
    cancel: __('Cancel'),
    unexpectedError: s__(
      'SshCertificates|An error occurred while adding the SSH certificate authority. Please try again.',
    ),
  },
  TITLE_MAX_LENGTH,
  KEY_MAX_LENGTH,
};
</script>

<template>
  <gl-form data-testid="add-certificate-authority-form" @submit.prevent="onSubmit">
    <gl-alert
      v-if="hasUnexpectedError"
      variant="danger"
      :dismissible="false"
      class="gl-mb-5"
      data-testid="unexpected-error-alert"
    >
      {{ $options.i18n.unexpectedError }}
    </gl-alert>

    <gl-form-group
      :label="$options.i18n.titleLabel"
      :description="$options.i18n.titleDescription"
      :state="fieldState(titleError)"
      :invalid-feedback="titleError"
      label-for="certificate-authority-title"
    >
      <gl-form-input
        id="certificate-authority-title"
        v-model="title"
        :maxlength="$options.TITLE_MAX_LENGTH"
        :state="fieldState(titleError)"
        :disabled="isSaving"
        data-testid="certificate-authority-title-input"
      />
    </gl-form-group>

    <gl-form-group
      :label="$options.i18n.keyLabel"
      :description="$options.i18n.keyDescription"
      :state="fieldState(keyError)"
      :invalid-feedback="keyError"
      label-for="certificate-authority-key"
    >
      <gl-form-textarea
        id="certificate-authority-key"
        v-model="key"
        rows="3"
        :maxlength="$options.KEY_MAX_LENGTH"
        :state="fieldState(keyError)"
        :disabled="isSaving"
        data-testid="certificate-authority-key-input"
      />
    </gl-form-group>

    <div class="gl-flex gl-gap-3">
      <gl-button
        type="submit"
        variant="confirm"
        :loading="isSaving"
        data-testid="submit-certificate-authority-button"
      >
        {{ $options.i18n.submit }}
      </gl-button>
      <gl-button
        type="button"
        :disabled="isSaving"
        data-testid="cancel-certificate-authority-button"
        @click="$emit('cancel')"
      >
        {{ $options.i18n.cancel }}
      </gl-button>
    </div>
  </gl-form>
</template>
