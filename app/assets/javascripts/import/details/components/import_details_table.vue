<script>
import { GlEmptyState, GlIcon, GlLink, GlTable } from '@gitlab/ui';
import { __ } from '~/locale';

import PaginationBar from '~/vue_shared/components/pagination_bar/pagination_bar.vue';
import { STATISTIC_ITEMS } from '../../constants';

const DEFAULT_PAGE_SIZE = 20;

export default {
  components: {
    GlEmptyState,
    GlIcon,
    GlLink,
    GlTable,
    PaginationBar,
  },
  STATISTIC_ITEMS,
  LOCAL_STORAGE_KEY: 'gl-import-details-page-size',
  fields: [
    {
      key: 'type',
      label: __('Type'),
      tdClass: 'gl-white-space-nowrap',
    },
    {
      key: 'title',
      label: __('Title'),
      tdClass: 'gl-md-w-30 gl-word-break-word',
    },
    {
      key: 'url',
      label: __('URL'),
      tdClass: 'gl-white-space-nowrap',
    },
    {
      key: 'details',
      label: __('Details'),
    },
  ],
  data() {
    return {
      page: 1,
      perPage: DEFAULT_PAGE_SIZE,
    };
  },
  computed: {
    items() {
      return [];
    },

    hasItems() {
      return this.items.length > 0;
    },

    pageInfo() {
      const mockPageInfo = {
        page: this.page,
        perPage: this.perPage,
        totalPages: this.page,
        total: this.items.length,
      };
      return mockPageInfo;
    },
  },

  methods: {
    setPage(page) {
      this.page = page;
    },

    setPageSize(size) {
      this.perPage = size;
      this.page = 1;
    },
  },
};
</script>

<template>
  <div>
    <gl-table :fields="$options.fields" :items="items" class="gl-mt-5" show-empty>
      <template #empty>
        <gl-empty-state :title="s__('Import|No import details')" />
      </template>

      <template #cell(type)="{ item: { type } }">
        {{ $options.STATISTIC_ITEMS[type] }}
      </template>
      <template #cell(url)="{ item: { url } }">
        <gl-link v-if="url" :href="url" target="_blank">
          {{ url }}
          <gl-icon name="external-link" />
        </gl-link>
      </template>
    </gl-table>
    <pagination-bar
      v-if="hasItems"
      :page-info="pageInfo"
      class="gl-mt-5"
      :storage-key="$options.LOCAL_STORAGE_KEY"
      @set-page="setPage"
      @set-page-size="setPageSize"
    />
  </div>
</template>
