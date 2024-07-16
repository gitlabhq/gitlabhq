import Vue from 'vue';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { parseBoolean } from '~/lib/utils/common_utils';
import RelatedIssuesRoot from './components/related_issues_root.vue';

export function initRelatedIssues() {
  const el = document.querySelector('.js-related-issues-root');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'RelatedIssuesRoot',
    apolloProvider,
    provide: {
      fullPath: el.dataset.fullPath,
      hasIssueWeightsFeature: parseBoolean(el.dataset.hasIssueWeightsFeature),
      hasIterationsFeature: parseBoolean(el.dataset.hasIterationsFeature),
      isGroup: parseBoolean(el.dataset.isGroup),
      // for work item modal
      canAdminLabel: el.dataset.wiCanAdminLabel,
      groupPath: el.dataset.wiGroupPath,
      issuesListPath: el.dataset.wiIssuesListPath,
      labelsManagePath: el.dataset.wiLabelsManagePath,
      reportAbusePath: el.dataset.wiReportAbusePath,
    },
    render: (createElement) =>
      createElement(RelatedIssuesRoot, {
        props: {
          endpoint: el.dataset.endpoint,
          canAdmin: parseBoolean(el.dataset.canAddRelatedIssues),
          helpPath: el.dataset.helpPath,
          showCategorizedIssues: parseBoolean(el.dataset.showCategorizedIssues),
          issuableType: el.dataset.issuableType,
          autoCompleteEpics: false,
        },
      }),
  });
}
