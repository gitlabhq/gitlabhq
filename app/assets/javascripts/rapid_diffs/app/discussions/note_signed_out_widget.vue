<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'NoteSignedOutWidget',
  components: {
    GlSprintf,
    GlLink,
  },
  signedOutPhrase: {
    message: __(
      'Please %{startTagRegister}register%{endRegisterTag} or %{startTagSignIn}sign in%{endSignInTag} to reply',
    ),
    placeholders: {
      register: ['startTagRegister', 'endRegisterTag'],
      signIn: ['startTagSignIn', 'endSignInTag'],
    },
  },
  inject: {
    endpoints: {
      type: Object,
    },
  },
};
</script>

<template>
  <div class="gl-flex-1 gl-text-center gl-text-subtle">
    <gl-sprintf
      :message="$options.signedOutPhrase.message"
      :placeholders="$options.signedOutPhrase.placeholders"
    >
      <template #register="{ content }">
        <gl-link :href="endpoints.register">{{ content }}</gl-link>
      </template>
      <template #signIn="{ content }">
        <gl-link :href="endpoints.signIn">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
