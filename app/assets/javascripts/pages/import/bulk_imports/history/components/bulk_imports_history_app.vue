<script>
import {
  GlEmptyState,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlTableLite,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { isEmpty, isEqual } from 'lodash';

import { s__, __ } from '~/locale';
import { createAlert } from '~/alert';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { getBulkImportHistory, getBulkImportsHistory } from '~/rest_api';
import { BULK_IMPORT_STATIC_ITEMS } from '~/import/constants';
import ImportStats from '~/import_entities/components/import_stats.vue';
import ImportStatus from '~/import_entities/import_groups/components/import_status.vue';
import { StatusPoller } from '~/import_entities/import_groups/services/status_poller';

import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import PaginationBar from '~/vue_shared/components/pagination_bar/pagination_bar.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

import { isFailed, isImporting } from '../utils';
import { DEFAULT_ERROR } from '../utils/error_messages';

const DEFAULT_PER_PAGE = 20;

const HISTORY_PAGINATION_SIZE_PERSIST_KEY = 'gl-bulk-imports-history-per-page';

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
    GlEmptyState,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlTableLite,
    PaginationBar,
    ImportStats,
    ImportStatus,
    TimeAgo,
    LocalStorageSync,
  },

  directives: {
    GlTooltip,
  },

  inject: {
    detailsPath: {
      default: undefined,
    },
    realtimeChangesPath: {
      default: undefined,
    },
  },

  props: {
    id: {
      type: String,
      required: false,
      default: null,
    },
  },

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
      key: 'source_full_path',
      label: s__('BulkImport|Source'),
      thClass: `gl-w-3/10`,
    }),
    tableCell({
      key: 'destination_name',
      label: s__('BulkImport|Destination'),
      thClass: `gl-w-3/10`,
    }),
    tableCell({
      key: 'created_at',
      label: __('Start date'),
    }),
    tableCell({
      key: 'status',
      label: __('Status'),
      thClass: `gl-w-1/4`,
    }),
  ],

  computed: {
    hasHistoryItems() {
      return this.historyItems.length > 0;
    },

    importingHistoryItemIds() {
      return this.historyItems
        .filter((item) => isImporting(item.status))
        .map((item) => item.bulk_import_id);
    },

    paginationConfigCopy() {
      return { ...this.paginationConfig };
    },
  },

  watch: {
    paginationConfigCopy: {
      handler(newValue, oldValue) {
        if (!isEqual(newValue, oldValue)) {
          this.loadHistoryItems();
        }
      },
      deep: true,
    },

    importingHistoryItemIds(value) {
      if (value.length > 0) {
        this.statusPoller.startPolling();
      } else {
        this.statusPoller.stopPolling();
      }
    },
  },

  mounted() {
    this.loadHistoryItems();

    this.statusPoller = new StatusPoller({
      pollPath: this.realtimeChangesPath,
      updateImportStatus: (update) => {
        if (!this.importingHistoryItemIds.includes(update.id)) {
          return;
        }

        const updateItemIndex = this.historyItems.findIndex(
          (item) => item.bulk_import_id === update.id,
        );
        const updateItem = this.historyItems[updateItemIndex];

        if (updateItem.status !== update.status_name) {
          const copy = [...this.historyItems];
          copy[updateItemIndex] = {
            ...updateItem,
            status: update.status_name,
          };

          this.historyItems = copy;
        }
      },
    });
  },

  beforeDestroy() {
    this.statusPoller.stopPolling();
  },

  methods: {
    fetchFn(params) {
      return this.id ? getBulkImportHistory(this.id, params) : getBulkImportsHistory(params);
    },

    async loadHistoryItems() {
      try {
        this.loading = true;

        const { data: historyItems, headers } = await this.fetchFn({
          page: this.paginationConfig.page,
          per_page: this.paginationConfig.perPage,
        });
        this.pageInfo = parseIntPagination(normalizeHeaders(headers));
        this.historyItems = historyItems;
      } catch (e) {
        createAlert({ message: e.message || DEFAULT_ERROR, captureError: true, error: e });
      } finally {
        this.loading = false;
      }
    },

    destinationLinkHref(params) {
      return joinPaths(gon.relative_url_root || '', '/', params.destination_full_path);
    },

    pathWithSuffix(path, item) {
      const suffix = item.entity_type === WORKSPACE_GROUP ? '/' : '';
      return `${path}${suffix}`;
    },

    destinationLinkText(item) {
      return this.pathWithSuffix(item.destination_full_path, item);
    },

    destinationText(item) {
      const fullPath = joinPaths(item.destination_namespace, item.destination_slug);
      return this.pathWithSuffix(fullPath, item);
    },

    hasStats(item) {
      return !isEmpty(item.stats);
    },

    showFailuresLinkInStatus(item) {
      if (isFailed(item.status)) {
        return true;
      }
      // Import has failures but no stats
      if (item.has_failures && !this.hasStats(item)) {
        return true;
      }

      return false;
    },

    failuresLinkHref(item) {
      if (!item.has_failures) {
        return '';
      }

      return this.detailsPath
        .replace(':id', encodeURIComponent(item.bulk_import_id))
        .replace(':entity_id', encodeURIComponent(item.id));
    },

    getEntityTooltip(item) {
      switch (item.entity_type) {
        case WORKSPACE_PROJECT:
          return __('Project');
        case WORKSPACE_GROUP:
          return __('Group');
        default:
          return '';
      }
    },

    setPageSize(size) {
      this.paginationConfig.perPage = size;
      this.paginationConfig.page = 1;
    },
  },

  gitlabLogo: window.gon.gitlab_logo,
  historyPaginationSizePersistKey: HISTORY_PAGINATION_SIZE_PERSIST_KEY,
  BULK_IMPORT_STATIC_ITEMS,
};
</script>

<template>
  <div>
    <h1 class="gl-my-0 gl-flex gl-items-center gl-gap-3 gl-py-4 gl-text-size-h1">
      <img :src="$options.gitlabLogo" :alt="__('GitLab Logo')" class="gl-h-6 gl-w-6" />
      <span>{{ s__('BulkImport|Migration history') }}</span>
    </h1>

    <gl-loading-icon v-if="loading" size="lg" class="gl-mt-5" />
    <gl-empty-state
      v-else-if="!hasHistoryItems"
      :title="s__('BulkImport|No history is available')"
      :description="s__('BulkImport|Your imported groups and projects will appear here.')"
    />
    <template v-else>
      <gl-table-lite :fields="$options.fields" :items="historyItems" class="gl-w-full">
        <template #cell(destination_name)="{ item }">
          <gl-icon
            v-gl-tooltip
            :name="item.entity_type"
            :title="getEntityTooltip(item)"
            :aria-label="getEntityTooltip(item)"
            variant="subtle"
          />
          <gl-link
            v-if="item.destination_full_path"
            :href="destinationLinkHref(item)"
            target="_blank"
          >
            {{ destinationLinkText(item) }}
          </gl-link>
          <span v-else>{{ destinationText(item) }}</span>
        </template>
        <template #cell(created_at)="{ value = '' }">
          <time-ago :time="value" />
        </template>
        <template #cell(status)="{ value, item }">
          <div>
            <import-status
              :has-failures="item.has_failures"
              :failures-href="showFailuresLinkInStatus(item) ? failuresLinkHref(item) : null"
              :status="value"
            />
            <import-stats
              v-if="hasStats(item)"
              :failures-href="failuresLinkHref(item)"
              :stats="item.stats"
              :stats-mapping="$options.BULK_IMPORT_STATIC_ITEMS"
              :status="value"
              class="gl-mt-2"
            />
          </div>
        </template>
      </gl-table-lite>
      <pagination-bar
        :page-info="pageInfo"
        class="gl-m-0 gl-mt-3"
        @set-page="paginationConfig.page = $event"
        @set-page-size="setPageSize"
      />
    </template>
    <local-storage-sync
      v-model="paginationConfig.perPage"
      :storage-key="$options.historyPaginationSizePersistKey"
    />
  </div>
</template>
