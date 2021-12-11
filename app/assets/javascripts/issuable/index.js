import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import IssuableContext from '~/issuable/issuable_context';
import { parseBoolean } from '~/lib/utils/common_utils';
import Sidebar from '~/right_sidebar';
import { getSidebarOptions } from '~/sidebar/mount_sidebar';
import CsvImportExportButtons from './components/csv_import_export_buttons.vue';
import IssuableByEmail from './components/issuable_by_email.vue';
import IssuableHeaderWarnings from './components/issuable_header_warnings.vue';

export function initCsvImportExportButtons() {
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
}

export function initIssuableByEmail() {
  Vue.use(GlToast);

  const el = document.querySelector('.js-issueable-by-email');

  if (!el) return null;

  const {
    initialEmail,
    issuableType,
    emailsHelpPagePath,
    quickActionsHelpPath,
    markdownHelpPath,
    resetPath,
  } = el.dataset;

  return new Vue({
    el,
    provide: {
      initialEmail,
      issuableType,
      emailsHelpPagePath,
      quickActionsHelpPath,
      markdownHelpPath,
      resetPath,
    },
    render(h) {
      return h(IssuableByEmail);
    },
  });
}

export function initIssuableHeaderWarnings(store) {
  const el = document.getElementById('js-issuable-header-warnings');

  if (!el) {
    return false;
  }

  const { hidden } = el.dataset;

  return new Vue({
    el,
    store,
    provide: { hidden: parseBoolean(hidden) },
    render(createElement) {
      return createElement(IssuableHeaderWarnings);
    },
  });
}

export function initIssuableSidebar() {
  const sidebarOptEl = document.querySelector('.js-sidebar-options');

  if (!sidebarOptEl) return;

  const sidebarOptions = getSidebarOptions(sidebarOptEl);

  new IssuableContext(sidebarOptions.currentUser); // eslint-disable-line no-new
  Sidebar.initialize();
}
