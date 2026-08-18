import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import RelatedMergeRequests from './components/related_merge_requests.vue';

export function initRelatedMergeRequests() {
  const el = document.querySelector('#js-related-merge-requests');

  if (!el) {
    return undefined;
  }
  Vue.use(VueApollo);

  const { hasClosingMergeRequest, projectPath, iid } = el.dataset;
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return initVueApp({
    apolloProvider,
    el,
    name: 'RelatedMergeRequestsRoot',
    component: RelatedMergeRequests,
    props: {
      hasClosingMergeRequest: parseBoolean(hasClosingMergeRequest),
      projectPath,
      iid,
    },
  });
}
