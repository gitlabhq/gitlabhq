import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import PipelineSummary from '~/ci/common/pipeline_summary/pipeline_summary.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (selector = '#js-commit-box-pipeline-summary') => {
  const el = document.querySelector(selector);

  if (!el) {
    return;
  }

  const { fullPath, iid, graphqlResourceEtag } = el.dataset;

  initVueApp({
    el,
    name: 'PipelineSummaryRoot',
    apolloProvider,
    component: PipelineSummary,
    props: { fullPath, iid, pipelineEtag: graphqlResourceEtag },
  });
};
