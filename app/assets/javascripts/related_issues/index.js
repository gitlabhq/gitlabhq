import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import RelatedIssuesRoot from './components/related_issues_root.vue';

export default function initRelatedIssues() {
  const relatedIssuesRootElement = document.querySelector('.js-related-issues-root');
  if (relatedIssuesRootElement) {
    // eslint-disable-next-line no-new
    new Vue({
      el: relatedIssuesRootElement,
      components: {
        relatedIssuesRoot: RelatedIssuesRoot,
      },
      render: (createElement) =>
        createElement('related-issues-root', {
          props: {
            endpoint: relatedIssuesRootElement.dataset.endpoint,
            canAdmin: parseBoolean(relatedIssuesRootElement.dataset.canAddRelatedIssues),
            helpPath: relatedIssuesRootElement.dataset.helpPath,
            showCategorizedIssues: parseBoolean(
              relatedIssuesRootElement.dataset.showCategorizedIssues,
            ),
          },
        }),
    });
  }
}
