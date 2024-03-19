<script>
import { GlKeysetPagination } from '@gitlab/ui';
import { __ } from '~/locale';
import OrganizationsListItem from './organizations_list_item.vue';

export default {
  name: 'OrganizationsList',
  components: {
    OrganizationsListItem,
    GlKeysetPagination,
  },
  i18n: {
    prev: __('Prev'),
    next: __('Next'),
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
    <ul class="gl-p-0 gl-list-style-none">
      <organizations-list-item
        v-for="organization in nodes"
        :key="organization.id"
        :organization="organization"
      />
    </ul>
    <div v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage" class="gl-text-center gl-mt-5">
      <gl-keyset-pagination
        v-bind="pageInfo"
        :prev-text="$options.i18n.prev"
        :next-text="$options.i18n.next"
        @prev="$emit('prev', $event)"
        @next="$emit('next', $event)"
      />
    </div>
  </div>
</template>
