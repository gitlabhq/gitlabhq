<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import WorkItemCsvExportModal from './work_items_csv_export_modal.vue';

export default {
  exportModalId: 'work-item-export-modal',
  components: {
    GlDisclosureDropdownItem,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    WorkItemCsvExportModal,
  },
  i18n: {
    exportAsCSV: s__('WorkItem|Export as CSV'),
    importFromJira: s__('WorkItem|Import from Jira'),
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    showExportButton: {
      default: false,
    },
    projectImportJiraPath: {
      default: null,
    },
    rssPath: {
      default: null,
    },
    calendarPath: {
      default: null,
    },
  },
  props: {
    workItemCount: {
      type: Number,
      required: false,
      default: undefined,
    },
    queryVariables: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    showImportExportButtons: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      showTooltip: false,
    };
  },
  computed: {
    importFromJira() {
      return {
        text: this.$options.i18n.importFromJira,
        href: this.projectImportJiraPath,
      };
    },
    exportAsCSV() {
      return {
        text: this.$options.i18n.exportAsCSV,
      };
    },
    dropdownTooltip() {
      return !this.showTooltip ? __('Actions') : '';
    },
    subscribeDropdownOptions() {
      return {
        items: [
          {
            text: __('Subscribe to RSS feed'),
            href: this.rssPath,
            extraAttrs: { 'data-testid': 'subscribe-rss' },
          },
          {
            text: __('Subscribe to calendar'),
            href: this.calendarPath,
            extraAttrs: { 'data-testid': 'subscribe-calendar' },
          },
        ],
      };
    },
    hasSubscriptionOptions() {
      return this.rssPath || this.calendarPath;
    },
    hasImportExportOptions() {
      return this.showImportExportButtons && (this.projectImportJiraPath || this.showExportButton);
    },
    shouldShowDropdown() {
      return this.hasImportExportOptions || this.hasSubscriptionOptions;
    },
  },
  methods: {
    showDropdown() {
      this.showTooltip = true;
    },
    hideDropdown() {
      this.showTooltip = false;
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-if="shouldShowDropdown"
    v-gl-tooltip
    category="tertiary"
    icon="ellipsis_v"
    no-caret
    toggle-text="Actions"
    :title="dropdownTooltip"
    text-sr-only
    data-testid="work-items-list-more-actions-dropdown"
    toggle-class="!gl-m-0 gl-h-full"
    class="!gl-w-7"
    @shown="showDropdown"
    @hidden="hideDropdown"
  >
    <template v-if="hasImportExportOptions">
      <gl-disclosure-dropdown-item
        v-if="projectImportJiraPath"
        data-testid="import-from-jira-link"
        :item="importFromJira"
      />

      <gl-disclosure-dropdown-item
        v-if="showExportButton"
        v-gl-modal="$options.exportModalId"
        data-testid="export-as-csv-button"
        :item="exportAsCSV"
      />

      <work-item-csv-export-modal
        v-if="showExportButton"
        :modal-id="$options.exportModalId"
        :work-item-count="workItemCount"
        :query-variables="queryVariables"
      />
    </template>
    <gl-disclosure-dropdown-group
      v-if="hasSubscriptionOptions"
      :bordered="hasImportExportOptions"
      :group="subscribeDropdownOptions"
    />
  </gl-disclosure-dropdown>
</template>
