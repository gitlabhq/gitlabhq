import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { resolvers } from '~/ci/pipeline_editor/graphql/resolvers';

import CiLint from './components/ci_lint.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(resolvers),
});

export default (containerId = '#js-ci-lint') => {
  const containerEl = document.querySelector(containerId);
  const { lintHelpPagePath, pipelineSimulationHelpPagePath, projectFullPath } = containerEl.dataset;

  return initVueApp({
    el: containerEl,
    name: 'CiLintRoot',
    apolloProvider,
    component: CiLint,
    props: {
      lintHelpPagePath,
      pipelineSimulationHelpPagePath,
      projectFullPath,
    },
  });
};
