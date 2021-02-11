import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import SecurityConfigurationApp from './components/app.vue';

export const initStaticSecurityConfiguration = (el) => {
  if (!el) {
    return null;
  }

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const { projectPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectPath,
    },
    render(createElement) {
      return createElement(SecurityConfigurationApp);
    },
  });
};
