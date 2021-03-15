<script>
import {
  GlButtonGroup,
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlTooltipDirective,
  GlModalDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';
import { ISSUABLE_TYPE } from '../constants';
import CsvExportModal from './csv_export_modal.vue';
import CsvImportModal from './csv_import_modal.vue';

export default {
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
      default: ISSUABLE_TYPE.issues,
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
  computed: {
    exportModalId() {
      return `${this.issuableType}-export-modal`;
    },
    importModalId() {
      return `${this.issuableType}-import-modal`;
    },
    importButtonText() {
      return this.showLabel ? this.$options.importIssuesText : null;
    },
    importButtonTooltipText() {
      return this.showLabel ? null : this.$options.importIssuesText;
    },
    importButtonIcon() {
      return this.showLabel ? null : 'import';
    },
  },
  importIssuesText: __('Import issues'),
};
</script>

<template>
  <div :class="containerClass">
    <gl-button-group>
      <gl-button
        v-if="showExportButton"
        v-gl-tooltip.hover="__('Export as CSV')"
        v-gl-modal="exportModalId"
        icon="export"
        data-qa-selector="export_as_csv_button"
        data-testid="export-csv-button"
      />
      <gl-dropdown
        v-if="showImportButton"
        v-gl-tooltip.hover="importButtonTooltipText"
        data-qa-selector="import_issues_dropdown"
        data-testid="import-csv-dropdown"
        :text="importButtonText"
        :icon="importButtonIcon"
      >
        <gl-dropdown-item v-gl-modal="importModalId" data-testid="import-csv-link">{{
          __('Import CSV')
        }}</gl-dropdown-item>
        <gl-dropdown-item
          v-if="canEdit"
          :href="projectImportJiraPath"
          data-qa-selector="import_from_jira_link"
          data-testid="import-from-jira-link"
          >{{ __('Import from Jira') }}</gl-dropdown-item
        >
      </gl-dropdown>
    </gl-button-group>
    <csv-export-modal v-if="showExportButton" :modal-id="exportModalId" />
    <csv-import-modal v-if="showImportButton" :modal-id="importModalId" />
  </div>
</template>
