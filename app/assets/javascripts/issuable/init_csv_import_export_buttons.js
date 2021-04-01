import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import CsvImportExportButtons from './components/csv_import_export_buttons.vue';

export default () => {
  const el = document.querySelector('.js-csv-import-export-buttons');

  if (!el) return null;

  const {
    showExportButton,
    showImportButton,
    issuableType,
    issuableCount,
    email,
    exportCsvPath,
    importCsvIssuesPath,
    containerClass,
    canEdit,
    projectImportJiraPath,
    maxAttachmentSize,
    showLabel,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      showExportButton: parseBoolean(showExportButton),
      showImportButton: parseBoolean(showImportButton),
      issuableType,
      email,
      importCsvIssuesPath,
      containerClass,
      canEdit: parseBoolean(canEdit),
      projectImportJiraPath,
      maxAttachmentSize,
      showLabel,
    },
    render(h) {
      return h(CsvImportExportButtons, {
        props: {
          exportCsvPath,
          issuableCount: parseInt(issuableCount, 10),
        },
      });
    },
  });
};
