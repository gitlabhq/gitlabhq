<script>
import { GlDropdownItem, GlModalDirective } from '@gitlab/ui';
import { TYPE_ISSUE } from '~/issues/constants';
import { __ } from '~/locale';
import CsvExportModal from './csv_export_modal.vue';
import CsvImportModal from './csv_import_modal.vue';

export default {
  i18n: {
    exportAsCsvButtonText: __('Export as CSV'),
    importCsvText: __('Import CSV'),
    importFromJiraText: __('Import from Jira'),
  },
  components: {
    GlDropdownItem,
    CsvExportModal,
    CsvImportModal,
  },
  directives: {
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
    canEdit: {
      default: false,
    },
    projectImportJiraPath: {
      default: null,
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
  },
};
</script>

<template>
  <ul class="gl-display-contents">
    <gl-dropdown-item
      v-if="showExportButton"
      v-gl-modal="exportModalId"
      data-qa-selector="export_as_csv_button"
    >
      {{ $options.i18n.exportAsCsvButtonText }}
    </gl-dropdown-item>
    <gl-dropdown-item v-if="showImportButton" v-gl-modal="importModalId">
      {{ $options.i18n.importCsvText }}
    </gl-dropdown-item>
    <gl-dropdown-item
      v-if="showImportButton && canEdit"
      :href="projectImportJiraPath"
      data-qa-selector="import_from_jira_link"
    >
      {{ $options.i18n.importFromJiraText }}
    </gl-dropdown-item>

    <csv-export-modal
      v-if="showExportButton"
      :modal-id="exportModalId"
      :export-csv-path="exportCsvPath"
      :issuable-count="issuableCount"
    />
    <csv-import-modal v-if="showImportButton" :modal-id="importModalId" />
  </ul>
</template>
