<script>
import ImportHistoryTableHeader from './import_history_table_header.vue';
import ImportHistoryTableRow from './import_history_table_row.vue';
import ImportHistoryTableSource from './import_history_table_source.vue';
import ImportHistoryTableRowDestination from './import_history_table_row_destination.vue';
import ImportHistoryTableRowStats from './import_history_table_row_stats.vue';
import ImportHistoryTableRowErrors from './import_history_table_row_errors.vue';
import ImportHistoryStatusBadge from './import_history_status_badge.vue';

/**
 * A flexible arrangement of import items, used for displaying projects when importing from 3rd parties.
 *
 * **Note**: semantically this is *not* a table, as there are nested elements and disclosures.
 */
export default {
  name: 'ImportSourceListTable',
  components: {
    ImportHistoryStatusBadge,
    ImportHistoryTableRowDestination,
    ImportHistoryTableHeader,
    ImportHistoryTableSource,
    ImportHistoryTableRow,
    ImportHistoryTableRowStats,
    ImportHistoryTableRowErrors,
  },
  props: {
    /**
     * This should be able to accept the data that comes from the BulkImport API.
     * An additional `action` key is accepted to define the label and buttonProps
     * for the button that can appear in the rightmost column.
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
     * @property {Object} [action] - Action details
     * @property {string} [action.label] - Button label
     * @property {Object} [action.buttonProps] - Props passed to the action button
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
      return item.stats && Object.keys(item.stats).length;
    },
    hasFailures(item) {
      return item.has_failures;
    },
    showToggle(item) {
      return Boolean(this.hasStats(item)) || this.hasFailures(item) || Boolean(item.nestedRow);
    },
  },
  gridClasses: 'gl-grid-cols-[repeat(2,1fr),150px,250px]',
};
</script>

<template>
  <div>
    <import-history-table-header :grid-classes="$options.gridClasses">
      <template #checkbox>
        <!-- 
          @slot Slot for passing a checkbox to select all selectable items.
          @binding items All the items 
        -->
        <slot :items="items" name="select-all-checkbox"></slot>
      </template>
      <template #column-1>
        {{ __('Source name') }}
      </template>
      <template #column-2>{{ __('Destination path') }}</template>
      <template #column-3>{{ __('Status') }}</template>
    </import-history-table-header>

    <import-history-table-row
      v-for="item in items"
      :key="item.id"
      :show-toggle="showToggle(item)"
      :grid-classes="$options.gridClasses"
    >
      <template #checkbox>
        <!-- 
          @slot Slot for passing a checkbox for each row that can be used to select it. Only displays if the row does not have a destination defined. Renders in place of the toggle button.
          @binding item The item for this row
        -->
        <slot name="row-checkbox" :item="item"></slot>
      </template>
      <template #column-1>
        <import-history-table-source :item="item" />
      </template>
      <template #column-2>
        <import-history-table-row-destination v-if="item.destination_slug" :item="item" />
        <!-- 
          @slot Slot for passing a destination input for items that do not have a destination defined.
          @binding item The item for this row
        -->
        <slot v-else :item="item" name="destination-input"></slot>
      </template>
      <template #column-3>
        <import-history-status-badge v-if="item.status_name" :status="item.status_name" />
      </template>
      <template #column-4>
        <!-- 
          @slot Slot for passing an action for the item. This will typically be a button that imports or re-imports.
          @binding item The item for this row
        -->
        <slot :item="item" name="action"></slot>
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
            <import-history-table-row-destination
              v-if="item.destination_slug"
              :item="item.nestedRow"
            />
            <slot v-else :item="item" name="nested-destination-input"></slot>
          </template>
          <template #column-3>
            <import-history-status-badge
              v-if="item.nestedRow.status_name"
              :status="item.nestedRow.status_name"
            />
          </template>
          <template #column-4> </template>
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
