import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import WorkItemsListApp from 'ee_else_ce/work_items/list/components/work_items_list_app.vue';

export const mountWorkItemsListApp = () => {
  const el = document.querySelector('.js-work-items-list-root');

  if (!el) {
    return null;
  }

  Vue.use(VueApollo);

  const {
    fullPath,
    hasEpicsFeature,
    hasIssuableHealthStatusFeature,
    hasIssueWeightsFeature,
    initialSort,
    isSignedIn,
  } = el.dataset;

  return new Vue({
    el,
    name: 'WorkItemsListRoot',
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide: {
      fullPath,
      hasEpicsFeature: parseBoolean(hasEpicsFeature),
      hasIssuableHealthStatusFeature: parseBoolean(hasIssuableHealthStatusFeature),
      hasIssueWeightsFeature: parseBoolean(hasIssueWeightsFeature),
      initialSort,
      isSignedIn: parseBoolean(isSignedIn),
    },
    render: (createComponent) => createComponent(WorkItemsListApp),
  });
};
