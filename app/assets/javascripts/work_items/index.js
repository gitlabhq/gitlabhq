import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { WORKSPACE_GROUP } from '~/issues/constants';
import { parseBoolean } from '~/lib/utils/common_utils';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import App from './components/app.vue';
import WorkItemRoot from './pages/work_item_root.vue';
import { createRouter } from './router';

Vue.use(VueApollo);

export const initWorkItemsRoot = (workspace) => {
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
    newCommentTemplatePath,
    reportAbusePath,
  } = el.dataset;

  const Component = workspace === WORKSPACE_GROUP ? WorkItemRoot : App;

  return new Vue({
    el,
    name: 'WorkItemsRoot',
    router: createRouter(el.dataset.fullPath),
    apolloProvider,
    provide: {
      fullPath,
      isGroup: workspace === WORKSPACE_GROUP,
      hasIssueWeightsFeature: parseBoolean(hasIssueWeightsFeature),
      hasOkrsFeature: parseBoolean(hasOkrsFeature),
      issuesListPath,
      registerPath,
      signInPath,
      hasIterationsFeature: parseBoolean(hasIterationsFeature),
      hasIssuableHealthStatusFeature: parseBoolean(hasIssuableHealthStatusFeature),
      newCommentTemplatePath,
      reportAbusePath,
    },
    render(createElement) {
      return createElement(Component, {
        props: {
          iid: workspace === WORKSPACE_GROUP ? iid : undefined,
        },
      });
    },
  });
};
