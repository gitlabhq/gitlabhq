import Vue from 'vue';
import apolloProvider from '~/issues/show/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import RelatedIssuesRoot from './components/related_issues_root.vue';

export function initRelatedIssues(issueType = 'issue') {
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
    },
    render: (createElement) =>
      createElement(RelatedIssuesRoot, {
        props: {
          endpoint: el.dataset.endpoint,
          canAdmin: parseBoolean(el.dataset.canAddRelatedIssues),
          helpPath: el.dataset.helpPath,
          showCategorizedIssues: parseBoolean(el.dataset.showCategorizedIssues),
          issuableType: issueType,
          autoCompleteEpics: false,
        },
      }),
  });
}
