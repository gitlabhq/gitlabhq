<script>
import {
  GlButton,
  GlEmptyState,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlTableLite,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { isEqual } from 'lodash';

import { s__, __ } from '~/locale';
import { createAlert } from '~/alert';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { joinPaths, getParameterValues } from '~/lib/utils/url_utility';
import { getBulkImportHistory, getBulkImportsHistory } from '~/rest_api';
import ImportStatus from '~/import_entities/import_groups/components/import_status.vue';
import { StatusPoller } from '~/import_entities/import_groups/services/status_poller';

import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import PaginationBar from '~/vue_shared/components/pagination_bar/pagination_bar.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import { isImporting } from '../utils';
import { DEFAULT_ERROR } from '../utils/error_messages';

const DEFAULT_PER_PAGE = 20;

const HISTORY_PAGINATION_SIZE_PERSIST_KEY = 'gl-bulk-imports-history-per-page';

const tableCell = (config) => ({
  tdClass: (value, key, item) => {
    return {
      // eslint-disable-next-line no-underscore-dangle
      'gl-border-b-0!': item._showDetails,
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
    GlTableLite,
    PaginationBar,
    ImportStatus,
    TimeAgo,
    LocalStorageSync,
  },

  directives: {
    GlTooltip,
  },

  mixins: [glFeatureFlagMixin()],

  inject: ['realtimeChangesPath'],

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
      thClass: `gl-w-30p`,
    }),
    tableCell({
      key: 'destination_name',
      label: s__('BulkImport|Destination'),
      thClass: `gl-w-40p`,
    }),
    tableCell({
      key: 'created_at',
      label: __('Start date'),
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

    importingHistoryItemIds() {
      return this.historyItems
        .filter((item) => isImporting(item.status))
        .map((item) => item.bulk_import_id);
    },

    showDetailsLink() {
      return this.glFeatures.bulkImportDetailsPage;
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
          this.$set(this.historyItems, updateItemIndex, {
            ...updateItem,
            status: update.status_name,
          });
        }
      },
    });
  },

  beforeDestroy() {
    this.statusPoller.stopPolling();
  },

  methods: {
    fetchFn(params) {
      const bulkImportId = getParameterValues('bulk_import_id')[0];

      return bulkImportId
        ? getBulkImportHistory(bulkImportId, params)
        : getBulkImportsHistory(params);
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
        createAlert({ message: DEFAULT_ERROR, captureError: true, error: e });
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
};
</script>

<template>
  <div>
    <h1 class="gl-font-size-h1 gl-my-0 gl-py-4 gl-display-flex gl-align-items-center gl-gap-3">
      <img :src="$options.gitlabLogo" class="gl-w-6 gl-h-6" />
      <span>{{ s__('BulkImport|Direct transfer history') }}</span>
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
            class="gl-text-gray-500"
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
        <template #cell(created_at)="{ value }">
          <time-ago :time="value" />
        </template>
        <template #cell(status)="{ value, item, toggleDetails, detailsShowing }">
          <div
            class="gl-display-flex gl-flex-direction-column gl-lg-flex-direction-row gl-align-items-flex-start gl-justify-content-space-between gl-gap-3"
          >
            <import-status
              :id="item.bulk_import_id"
              :entity-id="item.id"
              :has-failures="item.has_failures"
              :show-details-link="showDetailsLink"
              :status="value"
            />
            <gl-button
              v-if="!showDetailsLink && item.failures.length"
              :selected="detailsShowing"
              @click="toggleDetails"
              >{{ __('Details') }}</gl-button
            >
          </div>
        </template>
        <template #row-details="{ item }">
          <pre><code>{{ item.failures }}</code></pre>
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
