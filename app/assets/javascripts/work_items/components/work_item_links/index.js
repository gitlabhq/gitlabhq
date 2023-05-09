import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import WorkItemLinks from './work_item_links.vue';

Vue.use(GlToast);

export default function initWorkItemLinks() {
  const workItemLinksRoot = document.querySelector('.js-work-item-links-root');

  if (!workItemLinksRoot) {
    return null;
  }

  const {
    fullPath,
    wiHasIssueWeightsFeature,
    wiHasIterationsFeature,
    wiHasIssuableHealthStatusFeature,
    registerPath,
    signInPath,
    wiReportAbusePath,
  } = workItemLinksRoot.dataset;

  return new Vue({
    el: workItemLinksRoot,
    name: 'WorkItemLinksRoot',
    apolloProvider,
    components: {
      WorkItemLinks,
    },
    provide: {
      fullPath,
      hasIssueWeightsFeature: wiHasIssueWeightsFeature,
      hasIterationsFeature: wiHasIterationsFeature,
      hasIssuableHealthStatusFeature: wiHasIssuableHealthStatusFeature,
      registerPath,
      signInPath,
      reportAbusePath: wiReportAbusePath,
    },
    render: (createElement) =>
      createElement('work-item-links', {
        props: {
          issuableId: parseInt(workItemLinksRoot.dataset.issuableId, 10),
        },
      }),
  });
}
