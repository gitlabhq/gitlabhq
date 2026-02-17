<script>
import { GlKeysetPagination } from '@gitlab/ui';

import { TAB_NAME } from '~/ci/catalog/constants';
import CiResourcesListItem from './ci_resources_list_item.vue';
import CiAnalyticsList from './ci_analytics_list.vue';

export default {
  name: 'CiResourcesList',
  components: {
    CiResourcesListItem,
    CiAnalyticsList,
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
    currentTab: {
      type: String,
      required: true,
    },
  },
  emits: ['on-next-page', 'on-prev-page'],
  computed: {
    isAnalyticsTab() {
      return this.currentTab === TAB_NAME.analytics;
    },
  },
};
</script>
<template>
  <div>
    <ci-analytics-list v-if="isAnalyticsTab" :resources="resources" />
    <ul v-else class="gl-p-0" data-testId="catalog-list-container">
      <ci-resources-list-item
        v-for="resource in resources"
        :key="resource.id"
        :resource="resource"
      />
    </ul>
    <div class="gl-flex gl-justify-center">
      <gl-keyset-pagination
        v-bind="pageInfo"
        @prev="$emit('on-prev-page')"
        @next="$emit('on-next-page')"
      />
    </div>
  </div>
</template>
