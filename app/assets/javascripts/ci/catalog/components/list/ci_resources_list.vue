<script>
import { GlKeysetPagination } from '@gitlab/ui';

import CiResourcesListItem from './ci_resources_list_item.vue';

export default {
  name: 'CiResourcesList',
  components: {
    CiResourcesListItem,
    GlKeysetPagination,
  },
  props: {
    pageInfo: {
      type: Object,
      required: true,
    },
    resources: {
      type: Array,
      required: true,
    },
  },
  emits: ['onNextPage', 'onPrevPage'],
};
</script>
<template>
  <div>
    <ul class="gl-p-0" data-testId="catalog-list-container">
      <ci-resources-list-item
        v-for="resource in resources"
        :key="resource.id"
        :resource="resource"
      />
    </ul>
    <div class="gl-flex gl-justify-center">
      <gl-keyset-pagination
        v-bind="pageInfo"
        @prev="$emit('onPrevPage')"
        @next="$emit('onNextPage')"
      />
    </div>
  </div>
</template>
