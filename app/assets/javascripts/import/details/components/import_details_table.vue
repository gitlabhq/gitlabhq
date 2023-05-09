<script>
import { GlEmptyState, GlIcon, GlLink, GlLoadingIcon, GlTable } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { getParameterValues } from '~/lib/utils/url_utility';

import PaginationBar from '~/vue_shared/components/pagination_bar/pagination_bar.vue';
import { STATISTIC_ITEMS } from '../../constants';
import { fetchImportFailures } from '../api';

const DEFAULT_PAGE_SIZE = 20;

export default {
  components: {
    GlEmptyState,
    GlIcon,
    GlLink,
    GlLoadingIcon,
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

  i18n: {
    fetchErrorMessage: s__('Import|An error occurred while fetching import details.'),
    emptyText: s__('Import|No import details'),
  },

  inject: {
    failuresPath: {
      default: undefined,
    },
  },

  data() {
    return {
      items: [],
      loading: false,
      page: 1,
      perPage: DEFAULT_PAGE_SIZE,
      totalPages: 0,
      total: 0,
    };
  },

  computed: {
    hasItems() {
      return this.items.length > 0;
    },

    pageInfo() {
      return {
        page: this.page,
        perPage: this.perPage,
        totalPages: this.totalPages,
        total: this.total,
      };
    },
  },

  mounted() {
    this.loadImportFailures();
  },

  methods: {
    setPage(page) {
      this.page = page;
      this.loadImportFailures();
    },

    setPageSize(size) {
      this.perPage = size;
      this.page = 1;
      this.loadImportFailures();
    },

    async loadImportFailures() {
      if (!this.failuresPath) {
        return;
      }

      this.loading = true;
      try {
        const response = await fetchImportFailures(this.failuresPath, {
          projectId: getParameterValues('project_id')[0],
          page: this.page,
          perPage: this.perPage,
        });

        const { page, perPage, totalPages, total } = parseIntPagination(
          normalizeHeaders(response.headers),
        );
        this.page = page;
        this.perPage = perPage;
        this.totalPages = totalPages;
        this.total = total;
        this.items = response.data;
      } catch (error) {
        createAlert({ message: this.$options.i18n.fetchErrorMessage });
      }
      this.loading = false;
    },
  },
};
</script>

<template>
  <div>
    <gl-table :fields="$options.fields" :items="items" class="gl-mt-5" :busy="loading" show-empty>
      <template #table-busy>
        <gl-loading-icon size="lg" class="gl-my-5" />
      </template>

      <template #empty>
        <gl-empty-state :title="$options.i18n.emptyText" />
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
