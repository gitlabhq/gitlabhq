<script>
import ContainerExpirationPolicy from './container_expiration_policy.vue';

export default {
  components: {
    ContainerExpirationPolicy,
  },
};
</script>

<template>
  <section data-testid="registry-settings-app">
    <container-expiration-policy />
  </section>
</template>
