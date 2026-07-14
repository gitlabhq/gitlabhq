<script>
export default {
  name: 'VerificationDivider',
};
</script>

<template>
  <div class="gl-my-3 gl-flex gl-items-center gl-gap-3" data-testid="verification-divider">
    <hr class="gl-grow gl-border-default" />
    <span class="gl-text-subtle">{{ s__('TwoFactorAuth|or verify with') }}</span>
    <hr class="gl-grow gl-border-default" />
  </div>
</template>
