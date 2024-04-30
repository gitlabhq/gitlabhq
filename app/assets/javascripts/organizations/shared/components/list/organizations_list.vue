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
    <ul class="gl-p-0 gl-list-none">
      <organizations-list-item
        v-for="organization in nodes"
        :key="organization.id"
        :organization="organization"
      />
    </ul>
    <div v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage" class="gl-text-center gl-mt-5">
      <gl-keyset-pagination
        v-bind="pageInfo"
        @prev="$emit('prev', $event)"
        @next="$emit('next', $event)"
      />
    </div>
  </div>
</template>
