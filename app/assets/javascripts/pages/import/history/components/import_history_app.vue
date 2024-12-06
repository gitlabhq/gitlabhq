<script>
import { GlButton, GlEmptyState, GlIcon, GlLink, GlLoadingIcon, GlTable } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { createAlert } from '~/alert';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { getProjects } from '~/rest_api';
import ImportStatus from '~/import_entities/components/import_status.vue';
import PaginationBar from '~/vue_shared/components/pagination_bar/pagination_bar.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { DEFAULT_ERROR } from '../utils/error_messages';
import ImportErrorDetails from './import_error_details.vue';

const DEFAULT_PER_PAGE = 20;

const tableCell = (config) => ({
  tdClass: (value, key, item) => {
    return {
      // eslint-disable-next-line no-underscore-dangle
      '!gl-border-b-0': item._showDetails,
    };
  },
  ...config,
});

export default {
  components: {
    GlButton,
    GlEmptyState,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlTable,
    PaginationBar,
    ImportStatus,
    ImportErrorDetails,
    TimeAgo,
  },

  inject: ['assets'],

  data() {
    return {
      loading: true,
      historyItems: [],
      paginationConfig: {
        page: 1,
        perPage: DEFAULT_PER_PAGE,
      },
      pageInfo: {},
    };
  },

  fields: [
    tableCell({
      key: 'source',
      label: s__('BulkImport|Source'),
      thClass: 'gl-w-3/10',
    }),
    tableCell({
      key: 'destination',
      label: s__('BulkImport|Destination'),
      thClass: 'gl-w-4/10',
    }),
    tableCell({
      key: 'created_at',
      label: __('Date'),
    }),

    tableCell({
      key: 'status',
      label: __('Status'),
    }),
  ],

  computed: {
    hasHistoryItems() {
      return this.historyItems.length > 0;
    },
  },

  watch: {
    paginationConfig: {
      handler() {
        this.loadHistoryItems();
      },
      deep: true,
      immediate: true,
    },
  },

  methods: {
    async loadHistoryItems() {
      try {
        this.loading = true;
        const { data: historyItems, headers } = await getProjects(undefined, {
          imported: true,
          simple: false,
          page: this.paginationConfig.page,
          per_page: this.paginationConfig.perPage,
        });
        this.pageInfo = parseIntPagination(normalizeHeaders(headers));
        this.historyItems = historyItems;
      } catch (e) {
        createAlert({ message: DEFAULT_ERROR, captureError: true, error: e });
      } finally {
        this.loading = false;
      }
    },

    hasHttpProtocol(url) {
      try {
        const parsedUrl = new URL(url);
        return ['http:', 'https:'].includes(parsedUrl.protocol);
      } catch (e) {
        return false;
      }
    },

    setPageSize(size) {
      this.paginationConfig.perPage = size;
      this.paginationConfig.page = 1;
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-flex gl-items-center gl-border-0 gl-border-b-1 gl-border-solid gl-border-strong">
      <h1 class="gl-my-0 gl-py-4 gl-text-size-h1">
        <img :src="assets.gitlabLogo" class="gl-mb-2 gl-mr-2 gl-inline gl-h-6 gl-w-6" />
        {{ s__('BulkImport|Project import history') }}
      </h1>
    </div>
    <gl-loading-icon v-if="loading" size="lg" class="gl-mt-5" />
    <gl-empty-state
      v-else-if="!hasHistoryItems"
      :title="s__('BulkImport|No history is available')"
      :description="s__('BulkImport|Your imported projects will appear here.')"
    />
    <template v-else>
      <gl-table :fields="$options.fields" :items="historyItems" class="gl-w-full">
        <template #cell(source)="{ item }">
          <template v-if="item.import_url">
            <gl-link
              v-if="hasHttpProtocol(item.import_url)"
              :href="item.import_url"
              target="_blank"
            >
              {{ item.import_url }}
              <gl-icon name="external-link" class="gl-align-middle" />
            </gl-link>
            <span v-else>{{ item.import_url }}</span>
          </template>
          <span v-else>{{ s__('BulkImport|Template / File-based import / Direct transfer') }}</span>
        </template>
        <template #cell(destination)="{ item }">
          <gl-link :href="item.http_url_to_repo">
            {{ item.path_with_namespace }}
          </gl-link>
        </template>
        <template #cell(created_at)="{ value }">
          <time-ago :time="value" />
        </template>
        <template #cell(status)="{ item, toggleDetails, detailsShowing }">
          <import-status :status="item.import_status" class="gl-inline-block gl-w-13" />
          <gl-button
            v-if="item.import_status === 'failed'"
            class="gl-ml-3"
            :selected="detailsShowing"
            @click="toggleDetails"
            >{{ __('Details') }}</gl-button
          >
        </template>
        <template #row-details="{ item }">
          <import-error-details :id="item.id" />
        </template>
      </gl-table>
      <pagination-bar
        :page-info="pageInfo"
        class="gl-m-0 gl-mt-3"
        @set-page="paginationConfig.page = $event"
        @set-page-size="setPageSize"
      />
    </template>
  </div>
</template>
