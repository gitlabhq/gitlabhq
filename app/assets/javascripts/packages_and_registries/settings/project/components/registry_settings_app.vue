<script>
import ContainerExpirationPolicy from './container_expiration_policy.vue';
import PackagesCleanupPolicy from './packages_cleanup_policy.vue';

export default {
  components: {
    ContainerExpirationPolicy,
    PackagesCleanupPolicy,
  },
  inject: ['showContainerRegistrySettings', 'showPackageRegistrySettings'],
};
</script>

<template>
  <div>
    <packages-cleanup-policy v-if="showPackageRegistrySettings" />
    <container-expiration-policy v-if="showContainerRegistrySettings" />
  </div>
</template>
