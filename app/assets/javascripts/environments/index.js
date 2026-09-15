import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseBoolean } from '../lib/utils/common_utils';
import { apolloProvider } from './graphql/client';
import EnvironmentsApp from './components/environments_app.vue';

Vue.use(VueApollo);

export default (el) => {
  if (el) {
    const {
      canCreateEnvironment,
      endpoint,
      newEnvironmentPath,
      helpPagePath,
      projectPath,
      projectId,
    } = el.dataset;

    return initVueApp({
      el,
      name: 'EnvironmentsAppRoot',
      apolloProvider: apolloProvider(endpoint),
      provide: {
        projectPath,
        newEnvironmentPath,
        helpPagePath,
        projectId,
        canCreateEnvironment: parseBoolean(canCreateEnvironment),
      },
      component: EnvironmentsApp,
    });
  }

  return null;
};
