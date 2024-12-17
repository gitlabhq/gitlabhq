import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import PipelineSummary from '~/ci/common/pipeline_summary/pipeline_summary.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (selector = '.js-commit-box-pipeline-summary') => {
  const el = document.querySelector(selector);

  if (!el) {
    return;
  }

  const { fullPath, iid, graphqlResourceEtag } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(PipelineSummary, {
        props: { fullPath, iid, pipelineEtag: graphqlResourceEtag },
      });
    },
  });
};
