<script>
import { GlEmptyState, GlLoadingIcon, GlTableLite } from '@gitlab/ui';
import EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/status/status-nothing-md.svg';
import { createAlert } from '~/alert';
import { parseErrorMessage } from '~/lib/utils/error_message';
import { s__, __ } from '~/locale';
import { getOfflineExports } from '~/rest_api';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import ExportStatusBadge from './components/export_status_badge.vue';

const MAX_EXPORTS_PER_PAGE = 100;

export default {
  name: 'OfflineTransferExportHistoryApp',
  components: {
    ExportStatusBadge,
    GlEmptyState,
    GlLoadingIcon,
    GlTableLite,
    TimeAgo,
  },
  data() {
    return {
      loading: true,
      offlineExports: [],
    };
  },
  computed: {
    displayableExports() {
      // defensive handling for pre-19.4 code when bucket & export_prefix were absent
      return this.offlineExports.filter(
        ({ bucket, export_prefix: exportPrefix }) => bucket && exportPrefix,
      );
    },
    hasExports() {
      return this.displayableExports.length > 0;
    },
  },
  mounted() {
    this.loadExportHistory();
  },
  methods: {
    async loadExportHistory() {
      this.loading = true;

      try {
        const { data } = await getOfflineExports({ per_page: MAX_EXPORTS_PER_PAGE });
        this.offlineExports = data;
      } catch (error) {
        createAlert({
          message: parseErrorMessage(
            error,
            s__(
              'OfflineTransferExport|Something went wrong while fetching offline export history.',
            ),
          ),
          captureError: true,
          error,
        });
      } finally {
        this.loading = false;
      }
    },
  },
  fields: [
    {
      key: 'bucket',
      label: s__('OfflineTransferExport|Destination bucket'),
      thClass: '@md/panel:gl-w-3/10',
      tdClass: 'gl-wrap-anywhere',
    },
    {
      key: 'export_prefix',
      label: s__('OfflineTransferExport|Export prefix'),
      thClass: '@md/panel:gl-w-3/10',
      tdClass: 'gl-wrap-anywhere',
    },
    {
      key: 'created_at',
      label: __('Start date'),
      thClass: '@md/panel:gl-w-1/5',
    },
    {
      key: 'status',
      label: __('Status'),
      thClass: '@md/panel:gl-w-1/5',
    },
  ],
  EMPTY_STATE_SVG_URL,
};
</script>

<template>
  <div>
    <header class="gl-my-5">
      <h1 class="gl-heading-display">
        {{ s__('OfflineTransferExport|Offline export history') }}
      </h1>
    </header>

    <gl-loading-icon v-if="loading" size="lg" class="gl-mt-5" />

    <gl-empty-state
      v-else-if="!hasExports"
      :svg-path="$options.EMPTY_STATE_SVG_URL"
      :title="s__('OfflineTransferExport|No history is available yet')"
      :description="
        s__('OfflineTransferExport|Groups exported through offline transfer appear here.')
      "
    />

    <gl-table-lite
      v-else
      :fields="$options.fields"
      :items="displayableExports"
      stacked="md"
      data-testid="export-history-table"
      class="gl-w-full"
    >
      <template #cell(created_at)="{ value }">
        <time-ago :time="value" />
      </template>

      <template #cell(status)="{ value, item }">
        <export-status-badge :status="value" :has-failures="item.has_failures" />
      </template>
    </gl-table-lite>
  </div>
</template>
