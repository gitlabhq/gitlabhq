import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { parseBoolean } from '~/lib/utils/common_utils';
import RelatedIssuesRoot from './components/related_issues_root.vue';

export function initRelatedIssues() {
  const el = document.querySelector('.js-related-issues-root');

  if (!el) {
    return null;
  }

  return initVueApp({
    el,
    name: 'RelatedIssuesAppRoot',
    apolloProvider,
    component: RelatedIssuesRoot,
    props: {
      endpoint: el.dataset.endpoint,
      canAdmin: parseBoolean(el.dataset.canAddRelatedIssues),
      helpPath: el.dataset.helpPath,
      showCategorizedIssues: parseBoolean(el.dataset.showCategorizedIssues),
      issuableType: el.dataset.issuableType,
      autoCompleteEpics: false,
    },
  });
}
