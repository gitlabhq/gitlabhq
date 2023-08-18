<script>
import OrganizationAvatar from './organization_avatar.vue';

export default {
  name: 'OrganizationShowApp',
  components: { OrganizationAvatar },
  props: {
    organization: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-py-6">
    <organization-avatar :organization="organization" />
  </div>
</template>
