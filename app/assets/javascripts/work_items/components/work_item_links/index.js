import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import WorkItemLinks from './work_item_links.vue';

Vue.use(GlToast);

export default function initWorkItemLinks() {
  const workItemLinksRoot = document.querySelector('.js-work-item-links-root');

  if (!workItemLinksRoot) {
    return;
  }

  const {
    projectPath,
    wiHasIssueWeightsFeature,
    iid,
    wiHasIterationsFeature,
    wiHasIssuableHealthStatusFeature,
  } = workItemLinksRoot.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el: workItemLinksRoot,
    name: 'WorkItemLinksRoot',
    apolloProvider,
    components: {
      WorkItemLinks,
    },
    provide: {
      projectPath,
      iid,
      fullPath: projectPath,
      hasIssueWeightsFeature: wiHasIssueWeightsFeature,
      hasIterationsFeature: wiHasIterationsFeature,
      hasIssuableHealthStatusFeature: wiHasIssuableHealthStatusFeature,
    },
    render: (createElement) =>
      createElement('work-item-links', {
        props: {
          issuableId: parseInt(workItemLinksRoot.dataset.issuableId, 10),
        },
      }),
  });
}
