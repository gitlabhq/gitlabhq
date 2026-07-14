<script>
import { GlButton, GlSprintf } from '@gitlab/ui';

export default {
  name: 'VerificationRecoverAccount',
  components: {
    GlButton,
    GlSprintf,
  },
  emits: ['recover'],
};
</script>

<template>
  <p class="gl-mt-5 gl-flex gl-flex-wrap gl-gap-2 gl-text-subtle">
    <gl-sprintf
      :message="
        s__(
          'TwoFactorAuth|Having trouble signing in? %{buttonStart}Recover your account%{buttonEnd}',
        )
      "
    >
      <template #button="{ content }">
        <gl-button
          variant="link"
          category="tertiary"
          data-testid="recovery-button"
          @click="$emit('recover')"
          >{{ content }}</gl-button
        >
      </template>
    </gl-sprintf>
  </p>
</template>
