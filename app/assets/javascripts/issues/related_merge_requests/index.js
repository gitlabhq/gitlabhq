import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import RelatedMergeRequests from './components/related_merge_requests.vue';
import createStore from './store';

export function initRelatedMergeRequests() {
  const el = document.querySelector('#js-related-merge-requests');

  if (!el) {
    return undefined;
  }

  const { endpoint, hasClosingMergeRequest, projectPath, projectNamespace } = el.dataset;

  return new Vue({
    el,
    name: 'RelatedMergeRequestsRoot',
    store: createStore(),
    render: (createElement) =>
      createElement(RelatedMergeRequests, {
        props: {
          endpoint,
          hasClosingMergeRequest: parseBoolean(hasClosingMergeRequest),
          projectNamespace,
          projectPath,
        },
      }),
  });
}
