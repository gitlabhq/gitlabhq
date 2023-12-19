<script>
import { GlBadge, GlButton, GlSprintf, GlToggle } from '@gitlab/ui';
import {
  I18N_STATE_INTRO_PARAGRAPH,
  I18N_STATE_VERIFICATION_FINISHED_INTRO_PARAGRAPH,
  I18N_STATE_VERIFICATION_STARTED,
  I18N_RESET_BUTTON_LABEL,
  I18N_STATE_VERIFICATION_FAILED,
  I18N_STATE_VERIFICATION_FINISHED_TOGGLE_LABEL,
  I18N_STATE_VERIFICATION_FINISHED_TOGGLE_HELP,
  I18N_STATE_RESET_PARAGRAPH,
  I18N_VERIFICATION_ERRORS,
} from '../custom_email_constants';

export default {
  components: {
    GlBadge,
    GlButton,
    GlSprintf,
    GlToggle,
  },
  I18N_STATE_VERIFICATION_STARTED,
  I18N_STATE_VERIFICATION_FAILED,
  I18N_STATE_VERIFICATION_FINISHED_TOGGLE_LABEL,
  I18N_STATE_VERIFICATION_FINISHED_TOGGLE_HELP,
  I18N_RESET_BUTTON_LABEL,
  props: {
    incomingEmail: {
      type: String,
      required: true,
    },
    customEmail: {
      type: String,
      required: true,
    },
    smtpAddress: {
      type: String,
      required: true,
    },
    verificationState: {
      type: String,
      required: true,
    },
    verificationError: {
      type: String,
      required: false,
      default: '',
    },
    isEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isVerificationFailed() {
      return this.verificationState === 'failed';
    },
    isVerificationFinished() {
      return this.verificationState === 'finished';
    },
    containerClass() {
      return this.isVerificationFinished ? '' : 'gl-text-center';
    },
    introNote() {
      return this.isVerificationFinished
        ? I18N_STATE_VERIFICATION_FINISHED_INTRO_PARAGRAPH
        : I18N_STATE_INTRO_PARAGRAPH;
    },
    badgeVariant() {
      return this.isVerificationFailed ? 'danger' : 'info';
    },
    badgeContent() {
      return this.isVerificationFailed
        ? I18N_STATE_VERIFICATION_FAILED
        : I18N_STATE_VERIFICATION_STARTED;
    },
    verificationErrorI18nObject() {
      return I18N_VERIFICATION_ERRORS[this.verificationError];
    },
    errorLabel() {
      return this.verificationErrorI18nObject?.label;
    },
    errorDescription() {
      return this.verificationErrorI18nObject?.description;
    },
    resetNote() {
      return I18N_STATE_RESET_PARAGRAPH[this.verificationState];
    },
  },
};
</script>

<template>
  <div :class="containerClass">
    <p>
      <gl-sprintf :message="introNote">
        <template #customEmail>
          <strong>{{ customEmail }}</strong>
        </template>
        <template #smtpAddress>
          <strong>{{ smtpAddress }}</strong>
        </template>
        <template #badge="{ content }">
          <gl-badge variant="success">{{ content }}</gl-badge>
        </template>
      </gl-sprintf>
    </p>

    <div v-if="!isVerificationFinished" class="gl-mb-5">
      <gl-badge :variant="badgeVariant">{{ badgeContent }}</gl-badge>
    </div>

    <template v-if="isVerificationFinished">
      <gl-toggle
        :value="isEnabled"
        :is-loading="isSubmitting"
        :label="$options.I18N_STATE_VERIFICATION_FINISHED_TOGGLE_LABEL"
        :help="$options.I18N_STATE_VERIFICATION_FINISHED_TOGGLE_HELP"
        label-position="top"
        @change="$emit('toggle', $event)"
      />
      <hr />
    </template>

    <template v-if="verificationError">
      <p class="gl-mb-0">
        <strong>{{ errorLabel }}</strong>
      </p>
      <p>
        <gl-sprintf :message="errorDescription">
          <template #incomingEmail>
            <code>{{ incomingEmail }}</code>
          </template>
        </gl-sprintf>
      </p>
    </template>

    <p>{{ resetNote }}</p>
    <gl-button :loading="isSubmitting" @click="$emit('reset')">
      {{ $options.I18N_RESET_BUTTON_LABEL }}
    </gl-button>
  </div>
</template>
