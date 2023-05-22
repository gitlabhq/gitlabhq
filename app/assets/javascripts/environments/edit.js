import Vue from 'vue';
import VueApollo from 'vue-apollo';
import EditEnvironment from './components/edit_environment.vue';
import { apolloProvider } from './graphql/client';

Vue.use(VueApollo);

export default (el) => {
  if (!el) {
    return null;
  }

  const {
    projectEnvironmentsPath,
    updateEnvironmentPath,
    protectedEnvironmentSettingsPath,
    projectPath,
    environmentName,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider: apolloProvider(),
    provide: {
      projectEnvironmentsPath,
      updateEnvironmentPath,
      protectedEnvironmentSettingsPath,
      projectPath,
      environmentName,
    },
    render(h) {
      return h(EditEnvironment);
    },
  });
};
