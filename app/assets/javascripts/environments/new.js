import Vue from 'vue';
import VueApollo from 'vue-apollo';
import NewEnvironment from './components/new_environment.vue';
import { apolloProvider } from './graphql/client';

Vue.use(VueApollo);

export default (el) => {
  if (!el) {
    return null;
  }

  const { projectEnvironmentsPath, projectPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider: apolloProvider(),
    provide: { projectEnvironmentsPath, projectPath },
    render(h) {
      return h(NewEnvironment);
    },
  });
};
