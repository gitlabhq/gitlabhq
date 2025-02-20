<script>
import { GlButton, GlDrawer, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { RELATION_STATUS_DATA, IMPORT_HISTORY_TABLE_STATUS } from './constants';
import ImportHistoryTableRowErrors from './import_history_table_row_errors.vue';

/**
 * A basic component to show stats of an import. If failures are present, it displays a button to open a drawer of error details.
 */
export default {
  name: 'ImportHistoryTableRowStats',
  components: { GlButton, GlDrawer, GlIcon, ImportHistoryTableRowErrors },
  props: {
    /**
     * Should accept the data that comes form the BulkImport API
     */
    item: {
      type: Object,
      required: true,
    },
    /** Path for links to help docs on errors. Can be injected in parent. */
    detailsPath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      showDrawer: false,
    };
  },
  computed: {
    arrayOfStats() {
      return Object.entries(this.item.stats).map(([name, stat]) => ({ name, ...stat }));
    },
    hasFailures() {
      return this.item.has_failures;
    },
    buttonText() {
      return this.showDrawer ? s__('Import|Close details') : s__('Import|Open details');
    },
  },
  methods: {
    getIconProps(stat) {
      const { fetched, imported } = stat;
      if (fetched === imported) {
        if (imported === 0) {
          return RELATION_STATUS_DATA.pending;
        }

        return RELATION_STATUS_DATA.complete;
      }

      if (this.item.status_name === IMPORT_HISTORY_TABLE_STATUS.complete) {
        return RELATION_STATUS_DATA.failed;
      }

      return RELATION_STATUS_DATA['in-progress'];
    },
    toggleDrawer() {
      this.showDrawer = !this.showDrawer;
    },
  },
};
</script>

<template>
  <div>
    <ul class="gl-m-0 gl-flex gl-list-none gl-flex-col gl-gap-3 gl-p-0">
      <li
        v-for="stat in arrayOfStats"
        :key="stat.name"
        class="gl-flex gl-w-34 gl-items-center gl-gap-2"
        data-testid="import-history-table-row-stat"
      >
        <gl-icon v-bind="getIconProps(stat)" />
        <div data-testid="import-history-table-row-stat-name" class="gl-flex-grow">
          {{ stat.name }}
        </div>
        <div v-if="stat.source" data-testid="import-history-table-row-stat-count">
          {{ stat.imported.toLocaleString() }}/{{ stat.fetched.toLocaleString() }}
        </div>
      </li>
    </ul>
    <gl-button
      v-if="hasFailures"
      data-testid="import-history-table-row-stats-show-errors-button"
      class="gl-mt-3"
      @click="toggleDrawer"
      >{{ buttonText }}</gl-button
    >
    <gl-drawer
      :open="showDrawer"
      variant="sidebar"
      header-sticky
      class="gl-w-48"
      @close="toggleDrawer"
    >
      <template #title>
        <h2 class="gl-heading-3 gl-m-0">
          {{ __('Failures details') }}
        </h2>
      </template>
      <import-history-table-row-errors :item="item" :details-path="detailsPath" />
    </gl-drawer>
  </div>
</template>
