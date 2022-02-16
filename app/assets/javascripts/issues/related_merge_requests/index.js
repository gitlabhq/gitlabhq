import Vue from 'vue';
import RelatedMergeRequests from './components/related_merge_requests.vue';
import createStore from './store';

export function initRelatedMergeRequests() {
  const el = document.querySelector('#js-related-merge-requests');

  if (!el) {
    return undefined;
  }

  const { endpoint, projectPath, projectNamespace } = el.dataset;

  return new Vue({
    el,
    name: 'RelatedMergeRequestsRoot',
    store: createStore(),
    render: (createElement) =>
      createElement(RelatedMergeRequests, {
        props: { endpoint, projectNamespace, projectPath },
      }),
  });
}
