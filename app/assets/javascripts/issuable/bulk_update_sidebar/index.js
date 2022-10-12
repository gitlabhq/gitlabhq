import Vue from 'vue';
import StatusDropdown from './components/status_dropdown.vue';
import SubscriptionsDropdown from './components/subscriptions_dropdown.vue';
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

export function initStatusDropdown() {
  const el = document.querySelector('.js-status-dropdown');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'StatusDropdownRoot',
    render: (createElement) => createElement(StatusDropdown),
  });
}

export function initSubscriptionsDropdown() {
  const el = document.querySelector('.js-subscriptions-dropdown');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'SubscriptionsDropdownRoot',
    render: (createElement) => createElement(SubscriptionsDropdown),
  });
}
