<script>
import { GlKeysetPagination } from '@gitlab/ui';
import OrganizationsListItem from './organizations_list_item.vue';

export default {
  name: 'OrganizationsList',
  components: {
    OrganizationsListItem,
    GlKeysetPagination,
  },
  props: {
    organizations: {
      type: Object,
      required: true,
    },
  },
  computed: {
    nodes() {
      return this.organizations.nodes || [];
    },
    pageInfo() {
      return this.organizations.pageInfo || {};
    },
  },
};
</script>

<template>
  <div>
    <ul class="gl-list-none gl-p-0">
      <organizations-list-item
        v-for="organization in nodes"
        :key="organization.id"
        :organization="organization"
      />
    </ul>
    <div v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage" class="gl-mt-5 gl-text-center">
      <gl-keyset-pagination
        v-bind="pageInfo"
        @prev="$emit('prev', $event)"
        @next="$emit('next', $event)"
      />
    </div>
  </div>
</template>
