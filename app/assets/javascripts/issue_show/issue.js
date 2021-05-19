import Vue from 'vue';
import { mapGetters } from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import IssuableApp from './components/app.vue';
import HeaderActions from './components/header_actions.vue';
import { issueState } from './constants';
import apolloProvider from './graphql';
import getIssueStateQuery from './queries/get_issue_state.query.graphql';

const bootstrapApollo = (state = {}) => {
  return apolloProvider.clients.defaultClient.cache.writeQuery({
    query: getIssueStateQuery,
    data: {
      issueState: state,
    },
  });
};

export function initIssuableApp(issuableData, store) {
  const el = document.getElementById('js-issuable-app');

  if (!el) {
    return undefined;
  }

  bootstrapApollo({ ...issueState, issueType: el.dataset.issueType });

  return new Vue({
    el,
    apolloProvider,
    store,
    computed: {
      ...mapGetters(['getNoteableData']),
    },
    render(createElement) {
      return createElement(IssuableApp, {
        props: {
          ...issuableData,
          isConfidential: this.getNoteableData?.confidential,
          isLocked: this.getNoteableData?.discussion_locked,
          issuableStatus: this.getNoteableData?.state,
        },
      });
    },
  });
}

export function initIssueHeaderActions(store) {
  const el = document.querySelector('.js-issue-header-actions');

  if (!el) {
    return undefined;
  }

  bootstrapApollo({ ...issueState, issueType: el.dataset.issueType });

  return new Vue({
    el,
    apolloProvider,
    store,
    provide: {
      canCreateIssue: parseBoolean(el.dataset.canCreateIssue),
      canPromoteToEpic: parseBoolean(el.dataset.canPromoteToEpic),
      canReopenIssue: parseBoolean(el.dataset.canReopenIssue),
      canReportSpam: parseBoolean(el.dataset.canReportSpam),
      canUpdateIssue: parseBoolean(el.dataset.canUpdateIssue),
      iid: el.dataset.iid,
      isIssueAuthor: parseBoolean(el.dataset.isIssueAuthor),
      issueType: el.dataset.issueType,
      newIssuePath: el.dataset.newIssuePath,
      projectPath: el.dataset.projectPath,
      projectId: el.dataset.projectId,
      reportAbusePath: el.dataset.reportAbusePath,
      submitAsSpamPath: el.dataset.submitAsSpamPath,
    },
    render: (createElement) => createElement(HeaderActions),
  });
}
