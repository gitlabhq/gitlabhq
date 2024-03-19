import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlToast } from '@gitlab/ui';
import { parseBoolean } from '../lib/utils/common_utils';
import { apolloProvider } from './graphql/client';
import EnvironmentsApp from './components/environments_app.vue';

Vue.use(VueApollo);
Vue.use(GlToast);

export default (el) => {
  if (el) {
    const {
      canCreateEnvironment,
      endpoint,
      newEnvironmentPath,
      helpPagePath,
      projectPath,
      defaultBranchName,
      projectId,
    } = el.dataset;

    return new Vue({
      el,
      apolloProvider: apolloProvider(endpoint),
      provide: {
        projectPath,
        defaultBranchName,
        endpoint,
        newEnvironmentPath,
        helpPagePath,
        projectId,
        canCreateEnvironment: parseBoolean(canCreateEnvironment),
      },
      render(h) {
        return h(EnvironmentsApp);
      },
    });
  }

  return null;
};
