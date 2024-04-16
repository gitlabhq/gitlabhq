import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { WORKSPACE_GROUP } from '~/issues/constants';
import { parseBoolean } from '~/lib/utils/common_utils';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import App from './components/app.vue';
import { createRouter } from './router';

Vue.use(VueApollo);

export const initWorkItemsRoot = ({ workItemType, workspaceType } = {}) => {
  const el = document.querySelector('#js-work-items');

  if (!el) {
    return undefined;
  }

  const {
    fullPath,
    hasIssueWeightsFeature,
    iid,
    issuesListPath,
    registerPath,
    signInPath,
    hasIterationsFeature,
    hasOkrsFeature,
    hasIssuableHealthStatusFeature,
    newCommentTemplatePaths,
    reportAbusePath,
  } = el.dataset;

  const isGroup = workspaceType === WORKSPACE_GROUP;

  return new Vue({
    el,
    name: 'WorkItemsRoot',
    router: createRouter({ fullPath, workItemType, workspaceType }),
    apolloProvider,
    provide: {
      fullPath,
      isGroup,
      hasIssueWeightsFeature: parseBoolean(hasIssueWeightsFeature),
      hasOkrsFeature: parseBoolean(hasOkrsFeature),
      issuesListPath,
      registerPath,
      signInPath,
      hasIterationsFeature: parseBoolean(hasIterationsFeature),
      hasIssuableHealthStatusFeature: parseBoolean(hasIssuableHealthStatusFeature),
      newCommentTemplatePaths: JSON.parse(newCommentTemplatePaths),
      reportAbusePath,
    },
    render(createElement) {
      return createElement(App, {
        props: {
          iid: isGroup ? iid : undefined,
        },
      });
    },
  });
};
