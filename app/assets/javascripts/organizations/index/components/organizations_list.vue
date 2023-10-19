<script>
import OrganizationsListItem from './organizations_list_item.vue';

export default {
  name: 'OrganizationsList',
  components: {
    OrganizationsListItem,
  },
  props: {
    organizations: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <ul class="gl-p-0 gl-list-style-none">
    <organizations-list-item
      v-for="organization in organizations"
      :key="organization.id"
      :organization="organization"
    />
  </ul>
</template>
