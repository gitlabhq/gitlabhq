<script>
import {
  GlButtonGroup,
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlTooltipDirective,
  GlModalDirective,
} from '@gitlab/ui';
import { TYPE_ISSUE } from '~/issues/constants';
import { __ } from '~/locale';
import CsvExportModal from './csv_export_modal.vue';
import CsvImportModal from './csv_import_modal.vue';

export default {
  i18n: {
    exportAsCsvButtonText: __('Export as CSV'),
    importCsvText: __('Import CSV'),
    importFromJiraText: __('Import from Jira'),
    importIssuesText: __('Import issues'),
  },
  name: 'CsvImportExportButtons',
  components: {
    GlButtonGroup,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    CsvExportModal,
    CsvImportModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  inject: {
    issuableType: {
      default: TYPE_ISSUE,
    },
    showExportButton: {
      default: false,
    },
    showImportButton: {
      default: false,
    },
    containerClass: {
      default: '',
    },
    canEdit: {
      default: false,
    },
    projectImportJiraPath: {
      default: null,
    },
    showLabel: {
      default: false,
    },
  },
  props: {
    exportCsvPath: {
      type: String,
      required: false,
      default: '',
    },
    issuableCount: {
      type: Number,
      required: false,
      default: undefined,
    },
  },
  computed: {
    exportModalId() {
      return `${this.issuableType}-export-modal`;
    },
    importModalId() {
      return `${this.issuableType}-import-modal`;
    },
    importButtonTooltipText() {
      return this.showLabel ? null : this.$options.i18n.importIssuesText;
    },
    importButtonIcon() {
      return this.showLabel ? null : 'import';
    },
  },
};
</script>

<template>
  <div :class="containerClass">
    <gl-button-group class="gl-w-full">
      <gl-button
        v-if="showExportButton"
        v-gl-tooltip="$options.i18n.exportAsCsvButtonText"
        v-gl-modal="exportModalId"
        icon="export"
        :aria-label="$options.i18n.exportAsCsvButtonText"
        data-qa-selector="export_as_csv_button"
      />
      <gl-dropdown
        v-if="showImportButton"
        v-gl-tooltip="importButtonTooltipText"
        data-qa-selector="import_issues_dropdown"
        :text="$options.i18n.importIssuesText"
        :text-sr-only="!showLabel"
        :icon="importButtonIcon"
        class="gl-w-full gl-md-w-auto"
      >
        <gl-dropdown-item v-gl-modal="importModalId">
          {{ $options.i18n.importCsvText }}
        </gl-dropdown-item>
        <gl-dropdown-item
          v-if="canEdit"
          :href="projectImportJiraPath"
          data-qa-selector="import_from_jira_link"
        >
          {{ $options.i18n.importFromJiraText }}
        </gl-dropdown-item>
      </gl-dropdown>
    </gl-button-group>
    <csv-export-modal
      v-if="showExportButton"
      :modal-id="exportModalId"
      :export-csv-path="exportCsvPath"
      :issuable-count="issuableCount"
    />
    <csv-import-modal v-if="showImportButton" :modal-id="importModalId" />
  </div>
</template>
