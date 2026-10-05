import Vue from 'vue';
import { parseBoolean } from '@gitlab/frontend-utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { pinia } from '~/pinia/instance';
import { initReportAbuse } from '~/projects/report_abuse';
import MergeRequestTitleActions from '~/merge_requests/components/merge_request_title_actions.vue';

export default () => {
  const el = document.querySelector('.js-mr-title-actions');

  if (!el) return false;

  const {
    projectPath,
    iid,
    id,
    canUpdate,
    isSignedIn,
    editPath,
    reportAbusePath,
    codeDropdown,
    moreDropdown,
  } = el.dataset;

  let codeDropdownProps = null;
  let moreDropdownProps = {};

  try {
    codeDropdownProps = codeDropdown
      ? convertObjectPropsToCamelCase(JSON.parse(codeDropdown))
      : null;
  } catch {
    codeDropdownProps = null;
  }

  try {
    const raw = moreDropdown ? JSON.parse(moreDropdown) : {};
    const { mr, ...rest } = raw;
    const parsed = convertObjectPropsToCamelCase(rest);
    moreDropdownProps = {
      ...parsed,
      mr,
      reportedUserId: Number(parsed.reportedUserId),
      canUpdateMergeRequest: parseBoolean(parsed.canUpdateMergeRequest),
      open: parseBoolean(parsed.open),
      isMerged: parseBoolean(parsed.isMerged),
      sourceProjectMissing: parseBoolean(parsed.sourceProjectMissing),
      isCurrentUser: parseBoolean(parsed.isCurrentUser),
      aiOverviewAvailable: parseBoolean(parsed.aiOverviewAvailable),
      aiOverviewEnabled: parseBoolean(parsed.aiOverviewEnabled),
      // The lock item needs the sidebar bundle's lock form, which some pages
      // (e.g. conflicts) do not load, so it can be opted out via the dataset.
      showLock: parsed.showLock === undefined ? true : parseBoolean(parsed.showLock),
    };
  } catch {
    moreDropdownProps = {};
  }

  return new Vue({
    el,
    name: 'MergeRequestTitleActionsRoot',
    apolloProvider,
    pinia,
    provide: {
      isClassicSidebar: true,
      reportAbusePath,
    },
    beforeCreate() {
      initReportAbuse();
    },
    render: (createElement) =>
      createElement(MergeRequestTitleActions, {
        props: {
          projectPath,
          iid,
          id: Number(id),
          canUpdate: parseBoolean(canUpdate),
          isSignedIn: parseBoolean(isSignedIn),
          editPath,
          codeDropdownProps,
          moreDropdownProps,
        },
      }),
  });
};
