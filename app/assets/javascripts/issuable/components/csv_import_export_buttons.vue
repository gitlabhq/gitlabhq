<script>
import { GlDisclosureDropdownItem, GlModalDirective } from '@gitlab/ui';
import { TYPE_ISSUE } from '~/issues/constants';
import { __ } from '~/locale';
import CsvExportModal from './csv_export_modal.vue';
import CsvImportModal from './csv_import_modal.vue';

export default {
  components: {
    GlDisclosureDropdownItem,
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
    trackImportClick: {
      type: Boolean,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      dropdownItems: {
        exportAsCSV: {
          text: __('Export as CSV'),
        },
        importCSV: {
          text: __('Import CSV'),
        },
        importFromJIRA: {
          text: __('Import from Jira'),
          href: this.projectImportJiraPath,
        },
      },
    };
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
  <ul class="gl-contents">
    <gl-disclosure-dropdown-item
      v-if="showExportButton"
      v-gl-modal="exportModalId"
      data-testid="export-as-csv-button"
      :item="dropdownItems.exportAsCSV"
    />
    <gl-disclosure-dropdown-item
      v-if="showImportButton"
      v-gl-modal="importModalId"
      data-testid="import-from-csv-button"
      :item="dropdownItems.importCSV"
    />
    <gl-disclosure-dropdown-item
      v-if="showImportButton && canEdit"
      data-testid="import-from-jira-link"
      :item="dropdownItems.importFromJIRA"
    />

    <csv-export-modal
      v-if="showExportButton"
      :modal-id="exportModalId"
      :export-csv-path="exportCsvPath"
      :issuable-count="issuableCount"
    />
    <csv-import-modal v-if="showImportButton" :modal-id="importModalId" />
  </ul>
</template>
