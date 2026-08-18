import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import MlExperimentsIndex from './routes/experiments/index';

Vue.use(VueApollo);

export const initIndexMlExperiments = () => {
  const el = document.querySelector('#js-project-ml-experiments-index');

  if (!el) {
    return null;
  }

  const { projectPath, emptyStateSvgPath, mlflowTrackingUrl } = el.dataset;
  const props = {
    projectPath,
    emptyStateSvgPath,
    mlflowTrackingUrl,
  };

  const apolloProvider = new VueApollo({ defaultClient: createDefaultClient() });

  return initVueApp({
    el,
    name: 'MlExperimentsIndexApp',
    apolloProvider,
    component: MlExperimentsIndex,
    props,
  });
};
