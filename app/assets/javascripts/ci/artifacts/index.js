import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import App from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initArtifactsTable = () => {
  const el = document.querySelector('#js-artifact-management');

  if (!el) {
    return false;
  }

  const { projectPath, projectId, canDestroyArtifacts, jobArtifactsCountLimit } = el.dataset;

  return initVueApp({
    el,
    name: 'CiArtifactsRoot',
    apolloProvider,
    provide: {
      projectPath,
      projectId,
      canDestroyArtifacts: parseBoolean(canDestroyArtifacts),
      jobArtifactsCountLimit: parseInt(jobArtifactsCountLimit, 10),
    },
    component: App,
  });
};
