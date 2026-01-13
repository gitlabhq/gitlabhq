import VueApollo from 'vue-apollo';
import Vue from 'vue';
import createDefaultClient from '~/lib/graphql';
import PersonalAccessTokensApp from './components/app.vue';
import CreateGranularPersonalAccessTokenForm from './components/create_granular_token/create_granular_personal_access_token_form.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initPersonalAccessTokenApp = () => {
  const el = document.querySelector('#js-personal-access-token-app');

  if (!el) {
    return null;
  }

  const { accessTokenGranularNew } = el.dataset;

  return new Vue({
    el,
    name: 'PersonalAccessTokensRoot',
    apolloProvider,
    provide: {
      accessTokenGranularNewUrl: accessTokenGranularNew,
    },
    render(createElement) {
      return createElement(PersonalAccessTokensApp);
    },
  });
};

export const initCreateGranularTokenApp = () => {
  const el = document.querySelector('#js-create-granular-token-app');

  if (!el) {
    return null;
  }

  const { accessTokenMaxDate, accessTokenMinDate, accessTokenCreate } = el.dataset;

  return new Vue({
    el,
    name: 'CreateGranularTokenRoot',
    apolloProvider,
    provide: {
      accessTokenMaxDate,
      accessTokenMinDate,
      accessTokenTableUrl: accessTokenCreate,
    },
    render(createElement) {
      return createElement(CreateGranularPersonalAccessTokenForm);
    },
  });
};
