import VueApollo from 'vue-apollo';
import Vue from 'vue';
import createDefaultClient from '~/lib/graphql';
import PersonalAccessTokensApp from './components/app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initPersonalAccessTokenApp = () => {
  const el = document.querySelector('#js-personal-access-token-app');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'PersonalAccessTokensRoot',
    apolloProvider,
    render(createElement) {
      return createElement(PersonalAccessTokensApp);
    },
  });
};
