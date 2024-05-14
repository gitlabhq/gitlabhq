<script>
import { GlEmptyState, GlIcon, GlLink, GlLoadingIcon, GlTable } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { getParameterValues } from '~/lib/utils/url_utility';

import PaginationBar from '~/vue_shared/components/pagination_bar/pagination_bar.vue';
import { getBulkImportFailures } from '~/rest_api';
import { BULK_IMPORT_STATIC_ITEMS, STATISTIC_ITEMS } from '../../constants';
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

  i18n: {
    fetchErrorMessage: s__('Import|An error occurred while fetching import details.'),
    emptyText: s__('Import|No import details'),
  },

  inject: {
    failuresPath: {
      default: undefined,
    },
  },

  props: {
    id: {
      type: String,
      required: false,
      default: null,
    },

    entityId: {
      type: String,
      required: false,
      default: null,
    },

    bulkImport: {
      type: Boolean,
      required: false,
      default: false,
    },

    fields: {
      type: Array,
      required: true,
    },

    localStorageKey: {
      type: String,
      required: false,
      default: '',
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

    fetchFn(params) {
      return this.bulkImport
        ? getBulkImportFailures(this.id, this.entityId, params)
        : fetchImportFailures(this.failuresPath, {
            projectId: getParameterValues('project_id')[0],
            ...params,
          });
    },

    async loadImportFailures() {
      if (!this.bulkImport && !this.failuresPath) {
        return;
      }

      this.loading = true;

      try {
        const response = await this.fetchFn({ page: this.page, perPage: this.perPage });

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

    itemTypeText(type) {
      return (this.bulkImport ? BULK_IMPORT_STATIC_ITEMS[type] : STATISTIC_ITEMS[type]) || type;
    },
  },
};
</script>

<template>
  <div>
    <gl-table :fields="fields" :items="items" :busy="loading" show-empty>
      <template #table-busy>
        <gl-loading-icon size="lg" class="gl-my-5" />
      </template>

      <template #empty>
        <gl-empty-state :title="$options.i18n.emptyText" />
      </template>

      <template #cell(type)="{ item: { type } }">
        {{ itemTypeText(type) }}
      </template>
      <template #cell(provider_url)="{ item: { provider_url } }">
        <gl-link v-if="provider_url" :href="provider_url" target="_blank">
          {{ provider_url }}
          <gl-icon name="external-link" />
        </gl-link>
      </template>

      <template #cell(relation)="{ item: { relation } }">
        {{ itemTypeText(relation) }}
      </template>
      <template #cell(source_title)="{ item: { source_title, source_url } }">
        <gl-link v-if="source_url" :href="source_url" target="_blank">
          {{ source_title }}
          <gl-icon name="external-link" />
        </gl-link>
        <span v-else>
          {{ source_title }}
        </span>
      </template>
      <template #cell(error)="{ item: { exception_class, exception_message } }">
        <strong>{{ exception_class }}</strong>
        <p>{{ exception_message }}</p>
      </template>
    </gl-table>

    <pagination-bar
      v-if="hasItems"
      :page-info="pageInfo"
      class="gl-mt-5"
      :storage-key="localStorageKey"
      @set-page="setPage"
      @set-page-size="setPageSize"
    />
  </div>
</template>
