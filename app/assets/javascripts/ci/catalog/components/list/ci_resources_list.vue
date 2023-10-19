<script>
import { GlKeysetPagination } from '@gitlab/ui';

import { s__, sprintf } from '~/locale';
import { ciCatalogResourcesItemsCount } from '../../graphql/settings';
import CiResourcesListItem from './ci_resources_list_item.vue';

export default {
  components: {
    CiResourcesListItem,
    GlKeysetPagination,
  },
  props: {
    currentPage: {
      type: Number,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
    resources: {
      type: Array,
      required: true,
    },
    totalCount: {
      type: Number,
      required: true,
    },
  },
  computed: {
    showPageCount() {
      return typeof this.totalPageCount === 'number' && this.totalPageCount > 0;
    },
    totalPageCount() {
      return Math.ceil(this.totalCount / ciCatalogResourcesItemsCount);
    },
    pageText() {
      return sprintf(this.$options.i18n.pageText, {
        currentPage: this.currentPage,
        totalPage: this.totalPageCount,
      });
    },
  },
  i18n: {
    pageText: s__('CiCatalog|Page %{currentPage} of %{totalPage}'),
  },
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
    <div class="gl-display-flex gl-justify-content-center">
      <gl-keyset-pagination
        v-bind="pageInfo"
        @prev="$emit('onPrevPage')"
        @next="$emit('onNextPage')"
      />
    </div>
    <div
      v-if="showPageCount"
      class="gl-display-flex gl-justify-content-center gl-mt-3"
      data-testid="pageCount"
    >
      {{ pageText }}
    </div>
  </div>
</template>
