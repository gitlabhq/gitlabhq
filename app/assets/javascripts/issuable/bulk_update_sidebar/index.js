import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { gqlClient } from '../../issues/list/graphql';
import StatusDropdown from './components/status_dropdown.vue';
import SubscriptionsDropdown from './components/subscriptions_dropdown.vue';
import MoveIssuesButton from './components/move_issues_button.vue';
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

export function initMoveIssuesButton() {
  const el = document.querySelector('.js-move-issues');

  if (!el) {
    return null;
  }

  const { dataset } = el;

  Vue.use(VueApollo);
  const apolloProvider = new VueApollo({
    defaultClient: gqlClient,
  });

  return new Vue({
    el,
    name: 'MoveIssuesRoot',
    apolloProvider,
    render: (createElement) =>
      createElement(MoveIssuesButton, {
        props: {
          projectFullPath: dataset.projectFullPath,
          projectsFetchPath: dataset.projectsFetchPath,
        },
      }),
  });
}
