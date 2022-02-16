import Vue from 'vue';
import StatusSelect from './components/status_select.vue';
import issuableBulkUpdateActions from './issuable_bulk_update_actions';
import IssuableBulkUpdateSidebar from './issuable_bulk_update_sidebar';

export function initBulkUpdateSidebar(prefixId) {
  const el = document.querySelector('.issues-bulk-update');

  if (!el) {
    return;
  }

  issuableBulkUpdateActions.init({ prefixId });
  new IssuableBulkUpdateSidebar(); // eslint-disable-line no-new
}

export function initIssueStatusSelect() {
  const el = document.querySelector('.js-issue-status');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'StatusSelectRoot',
    render: (createElement) => createElement(StatusSelect),
  });
}
