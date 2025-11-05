<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import WorkItemByEmail from './work_item_by_email.vue';
import WorkItemCsvExportModal from './work_items_csv_export_modal.vue';
import WorkItemsCsvImportModal from './work_items_csv_import_modal.vue';

export default {
  exportModalId: 'work-item-export-modal',
  importModalId: 'work-item-import-modal',
  components: {
    GlDisclosureDropdownItem,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    WorkItemCsvExportModal,
    WorkItemsCsvImportModal,
    WorkItemByEmail,
  },
  i18n: {
    exportAsCSV: s__('WorkItem|Export as CSV'),
    importFromJira: s__('WorkItem|Import from Jira'),
    importCsv: s__('WorkItem|Import CSV'),
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
    canImportWorkItems: {
      default: false,
    },
    canEdit: {
      default: false,
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
    fullPath: {
      type: String,
      required: false,
      default: '',
    },
    showWorkItemByEmailButton: {
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
    importCsv() {
      return {
        text: this.$options.i18n.importCsv,
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
    isJiraImportVisible() {
      return Boolean(this.projectImportJiraPath) && this.canEdit;
    },
    hasImportExportOptions() {
      return Boolean(
        this.showImportExportButtons &&
          (this.isJiraImportVisible || this.showExportButton || this.canImportWorkItems),
      );
    },
    shouldShowDropdown() {
      return (
        this.hasImportExportOptions || this.hasSubscriptionOptions || this.showWorkItemByEmailButton
      );
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
        v-if="isJiraImportVisible"
        data-testid="import-from-jira-link"
        :item="importFromJira"
      />

      <gl-disclosure-dropdown-item
        v-if="showExportButton"
        v-gl-modal="$options.exportModalId"
        data-testid="export-as-csv-button"
        :item="exportAsCSV"
      />

      <gl-disclosure-dropdown-item
        v-if="canImportWorkItems"
        v-gl-modal="$options.importModalId"
        data-testid="import-csv-button"
        :item="importCsv"
      />

      <work-item-csv-export-modal
        v-if="showExportButton"
        :modal-id="$options.exportModalId"
        :work-item-count="workItemCount"
        :query-variables="queryVariables"
      />

      <work-items-csv-import-modal
        v-if="canImportWorkItems"
        :modal-id="$options.importModalId"
        :full-path="fullPath"
      />
    </template>
    <work-item-by-email
      v-if="showWorkItemByEmailButton"
      data-track-action="click_email_work_item_project_work_items_empty_list_page"
      data-track-label="email_work_item_project_work_items_empty_list"
    />
    <gl-disclosure-dropdown-group
      v-if="hasSubscriptionOptions"
      :bordered="hasImportExportOptions"
      :group="subscribeDropdownOptions"
    />
  </gl-disclosure-dropdown>
</template>
