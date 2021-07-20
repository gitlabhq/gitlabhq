import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import TokenAccess from './components/token_access.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initTokenAccess = (containerId = 'js-ci-token-access-app') => {
  const containerEl = document.getElementById(containerId);

  if (!containerEl) {
    return false;
  }

  const { fullPath } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    apolloProvider,
    provide: {
      fullPath,
    },
    render(createElement) {
      return createElement(TokenAccess);
    },
  });
};
