import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import WorkItemLinks from './work_item_links.vue';

Vue.use(GlToast);

export default function initWorkItemLinks() {
  if (!window.gon.features.workItemsHierarchy) {
    return;
  }

  const workItemLinksRoot = document.querySelector('.js-work-item-links-root');

  if (!workItemLinksRoot) {
    return;
  }

  const { projectPath, wiHasIssueWeightsFeature, iid } = workItemLinksRoot.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el: workItemLinksRoot,
    name: 'WorkItemLinksRoot',
    apolloProvider,
    components: {
      workItemLinks: WorkItemLinks,
    },
    provide: {
      projectPath,
      iid,
      fullPath: projectPath,
      hasIssueWeightsFeature: wiHasIssueWeightsFeature,
    },
    render: (createElement) =>
      createElement('work-item-links', {
        props: {
          issuableId: parseInt(workItemLinksRoot.dataset.issuableId, 10),
        },
      }),
  });
}
