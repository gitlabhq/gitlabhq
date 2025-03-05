<script>
import { GlAvatarLabeled } from '@gitlab/ui';
import TimeAgoTooltip from '../time_ago_tooltip.vue';

import ImportHistoryTableHeader from './import_history_table_header.vue';
import ImportHistoryTableRow from './import_history_table_row.vue';
import ImportHistoryTableSource from './import_history_table_source.vue';
import ImportHistoryTableRowDestination from './import_history_table_row_destination.vue';
import ImportHistoryTableRowStats from './import_history_table_row_stats.vue';
import ImportHistoryTableRowErrors from './import_history_table_row_errors.vue';
import ImportHistoryStatusBadge from './import_history_status_badge.vue';

/**
 * A flexible arrangement of import items, used for import history.
 *
 * **Note**: semantically this is *not* a table, as there are nested elements and disclosures.
 */
export default {
  name: 'ImportHistoryTable',
  components: {
    GlAvatarLabeled,
    ImportHistoryStatusBadge,
    TimeAgoTooltip,
    ImportHistoryTableRowDestination,
    ImportHistoryTableHeader,
    ImportHistoryTableSource,
    ImportHistoryTableRow,
    ImportHistoryTableRowStats,
    ImportHistoryTableRowErrors,
  },
  props: {
    /**
     * This should be able to accept the data that comes from the BulkImport API
     *
     * @typedef {Object} ImportItem
     * @property {Object} source - Source project details
     * @property {Object} destination - Target namespace details
     * @property {Object} stats - Import statistics
     * @property {number} stats.imported - Successfully imported count
     * @property {number} stats.fetched - Total fetched count
     * @property {Array<Object>} failures - Error details
     * @property {string} failures[].correlation_id_value - Error correlation ID
     * @property {string} failures[].exception_message - Human-readable error message
     * @property {string} [failures[].link_text] - Optional link text for error details
     * @property {string} [failures[].raw] - Raw error output
     *
     * @type {Array<ImportItem>}
     */
    items: {
      type: Array,
      default: () => [],
      required: true,
    },
    /** Path for links to help docs on errors. Can be injected in parent. */
    detailsPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  methods: {
    hasStats(item) {
      return Boolean(item.stats && Object.keys(item.stats).length);
    },
    hasFailures(item) {
      return item.has_failures;
    },
    showToggle(item) {
      return this.hasStats(item) || this.hasFailures(item) || Boolean(item.nestedRow);
    },
  },
  gridClasses: 'gl-grid-cols-[repeat(2,1fr),200px,150px]',
};
</script>

<template>
  <div>
    <import-history-table-header :grid-classes="$options.gridClasses">
      <template #column-1>
        {{ __('Source name') }}
      </template>
      <template #column-2>{{ __('Destination') }}</template>
      <template #column-3>{{ __('Start date') }}</template>
      <template #column-4>{{ __('Status') }}</template>
    </import-history-table-header>
    <import-history-table-row
      v-for="item in items"
      :key="item.id"
      data-testid="import-history-table-row"
      :show-toggle="showToggle(item)"
      :grid-classes="$options.gridClasses"
    >
      <template #column-1>
        <import-history-table-source :item="item" />
      </template>
      <template #column-2>
        <import-history-table-row-destination :item="item" />
      </template>
      <template #column-3>
        <div class="gl-flex gl-flex-col gl-gap-2">
          <gl-avatar-labeled v-if="item.userAvatarProps" v-bind="item.userAvatarProps" :size="16" />
          <time-ago-tooltip :time="item.created_at" />
        </div>
      </template>
      <template #column-4>
        <import-history-status-badge v-if="item.status_name" :status="item.status_name" />
      </template>
      <template v-if="item.nestedRow" #nested-row>
        <import-history-table-row
          data-testid="import-history-table-row-nested"
          :is-nested="true"
          :show-toggle="showToggle(item.nestedRow)"
          :grid-classes="$options.gridClasses"
        >
          <template #column-1>
            <import-history-table-source :item="item.nestedRow" />
          </template>
          <template #column-2>
            <import-history-table-row-destination :item="item.nestedRow" />
          </template>
          <template #column-3>
            <gl-avatar-labeled
              v-if="item.nestedRow.userAvatarProps"
              v-bind="item.nestedRow.userAvatarProps"
              :size="16"
            />
            <time-ago-tooltip :time="item.nestedRow.created_at" />
          </template>
          <template #column-4>
            <import-history-status-badge
              v-if="item.nestedRow.status_name"
              :status="item.nestedRow.status_name"
            />
          </template>
          <template #expanded-content>
            <import-history-table-row-stats
              v-if="hasStats(item.nestedRow)"
              :item="item.nestedRow"
              :details-path="detailsPath"
            />
            <import-history-table-row-errors
              v-else-if="hasFailures(item.nestedRow)"
              :item="item.nestedRow"
              :details-path="detailsPath"
            />
          </template>
        </import-history-table-row>
      </template>
      <template #expanded-content>
        <import-history-table-row-stats
          v-if="hasStats(item)"
          :item="item"
          :details-path="detailsPath"
        />
        <import-history-table-row-errors
          v-else-if="hasFailures(item)"
          :item="item"
          :details-path="detailsPath"
        />
      </template>
    </import-history-table-row>
  </div>
</template>
