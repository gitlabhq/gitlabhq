<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import AiCatalogListItem from './ai_catalog_list_item.vue';

export default {
  name: 'AiCatalogList',
  components: {
    AiCatalogListItem,
    GlSkeletonLoader,
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div data-testid="ai-catalog-list">
    <gl-skeleton-loader v-if="isLoading" :lines="2" />

    <ul v-else class="gl-list-style-none gl-m-0 gl-p-0">
      <ai-catalog-list-item v-for="item in items" :key="item.id" :item="item" />
    </ul>
  </div>
</template>
