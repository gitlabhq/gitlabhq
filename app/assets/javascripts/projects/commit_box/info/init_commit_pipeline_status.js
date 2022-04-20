import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import CommitBoxPipelineStatus from './components/commit_box_pipeline_status.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient({}, { useGet: true }),
});

export default (selector = '.js-commit-pipeline-status') => {
  const el = document.querySelector(selector);

  if (!el) {
    return;
  }

  const { fullPath, iid, graphqlResourceEtag } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    provide: {
      fullPath,
      iid,
      graphqlResourceEtag,
    },
    render(createElement) {
      return createElement(CommitBoxPipelineStatus);
    },
  });
};
