<script>
import { GlBadge, GlButton, GlSprintf } from '@gitlab/ui';
import {
  I18N_STATE_INTRO_PARAGRAPH,
  I18N_STATE_VERIFICATION_STARTED,
  I18N_STATE_VERIFICATION_STARTED_INFO_PARAGRAPH,
  I18N_RESET_BUTTON_LABEL,
} from '../custom_email_constants';

export default {
  components: {
    GlBadge,
    GlButton,
    GlSprintf,
  },
  I18N_STATE_INTRO_PARAGRAPH,
  I18N_STATE_VERIFICATION_STARTED,
  I18N_STATE_VERIFICATION_STARTED_INFO_PARAGRAPH,
  I18N_RESET_BUTTON_LABEL,
  props: {
    customEmail: {
      type: String,
      required: false,
      default: '',
    },
    smtpAddress: {
      type: String,
      required: false,
      default: '',
    },
    submitting: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div class="text-center">
    <p>
      <gl-sprintf :message="$options.I18N_STATE_INTRO_PARAGRAPH">
        <template #customEmail>
          <strong>{{ customEmail }}</strong>
        </template>
        <template #smtpAddress>
          <strong>{{ smtpAddress }}</strong>
        </template>
      </gl-sprintf>
    </p>
    <div class="gl-mb-5">
      <gl-badge variant="info">{{ $options.I18N_STATE_VERIFICATION_STARTED }}</gl-badge>
    </div>
    <p>{{ $options.I18N_STATE_VERIFICATION_STARTED_INFO_PARAGRAPH }}</p>
    <gl-button :loading="submitting" @click="$emit('reset')">
      {{ $options.I18N_RESET_BUTTON_LABEL }}
    </gl-button>
  </div>
</template>
