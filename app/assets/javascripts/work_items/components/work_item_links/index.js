import Vue from 'vue';
import { GlToast } from '@gitlab/ui';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { parseBoolean } from '~/lib/utils/common_utils';
import WorkItemLinks from './work_item_links.vue';

Vue.use(GlToast);

export default function initWorkItemLinks() {
  const workItemLinksRoot = document.querySelector('.js-work-item-links-root');

  if (!workItemLinksRoot) {
    return null;
  }

  const {
    fullPath,
    registerPath,
    signInPath,
    wiCanAdminLabel,
    wiGroupPath,
    wiHasIssueWeightsFeature,
    wiHasIterationsFeature,
    wiHasIssuableHealthStatusFeature,
    wiIssuesListPath,
    wiLabelsManagePath,
    wiReportAbusePath,
    wiNewTrialPath,
    hasLinkedItemsEpicsFeature,
  } = workItemLinksRoot.dataset;

  return initVueApp({
    el: workItemLinksRoot,
    name: 'WorkItemLinksRoot',
    apolloProvider,
    provide: {
      fullPath,
      registerPath,
      signInPath,
      // for work item modal
      canAdminLabel: wiCanAdminLabel,
      groupPath: wiGroupPath,
      hasIssueWeightsFeature: wiHasIssueWeightsFeature,
      hasIterationsFeature: wiHasIterationsFeature,
      hasIssuableHealthStatusFeature: wiHasIssuableHealthStatusFeature,
      issuesListPath: wiIssuesListPath,
      labelsManagePath: wiLabelsManagePath,
      reportAbusePath: wiReportAbusePath,
      planTrialPath: wiNewTrialPath,
      hasLinkedItemsEpicsFeature: parseBoolean(hasLinkedItemsEpicsFeature),
    },
    component: WorkItemLinks,
    props: {
      issuableId: parseInt(workItemLinksRoot.dataset.issuableId, 10),
      issuableIid: parseInt(workItemLinksRoot.dataset.issuableIid, 10),
    },
  });
}
