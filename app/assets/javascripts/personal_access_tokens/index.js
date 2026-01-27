import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { pinia } from '~/pinia/instance';
import createDefaultClient from '~/lib/graphql';
import PersonalAccessTokensApp from './components/app.vue';
import CreateGranularPersonalAccessTokenForm from './components/create_granular_token/create_granular_personal_access_token_form.vue';
import CreateLegacyPersonalAccessTokenForm from './components/create_legacy_token/create_legacy_personal_access_token_form.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initPersonalAccessTokenApp = () => {
  const el = document.querySelector('#js-personal-access-token-app');

  if (!el) {
    return null;
  }

  const { accessTokenGranularNew, accessTokenLegacyNew } = el.dataset;

  return new Vue({
    el,
    name: 'PersonalAccessTokensRoot',
    apolloProvider,
    provide: {
      accessTokenGranularNewUrl: accessTokenGranularNew,
      accessTokenLegacyNewUrl: accessTokenLegacyNew,
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

  const { accessTokenMaxDate, accessTokenMinDate, accessTokenTableUrl } = el.dataset;

  return new Vue({
    el,
    name: 'CreateGranularTokenRoot',
    apolloProvider,
    provide: {
      accessTokenMaxDate,
      accessTokenMinDate,
      accessTokenTableUrl,
    },
    render(createElement) {
      return createElement(CreateGranularPersonalAccessTokenForm);
    },
  });
};

export const initCreateLegacyTokenApp = () => {
  const el = document.querySelector('#js-create-legacy-token-app');

  if (!el) {
    return null;
  }

  const {
    accessTokenMaxDate,
    accessTokenMinDate,
    accessTokenAvailableScopes,
    accessTokenCreate,
    accessTokenNew,
    accessTokenRevoke,
    accessTokenRotate,
    accessTokenShow,
    accessTokenTableUrl,
  } = el.dataset;

  return new Vue({
    el,
    name: 'CreateLegacyTokenRoot',
    pinia,
    provide: {
      accessTokenAvailableScopes: JSON.parse(accessTokenAvailableScopes),
      accessTokenMaxDate,
      accessTokenMinDate,
      accessTokenCreate,
      accessTokenNew,
      accessTokenRevoke,
      accessTokenRotate,
      accessTokenShow,
      accessTokenTableUrl,
    },
    render(createElement) {
      return createElement(CreateLegacyPersonalAccessTokenForm, {
        props: {
          id: gon.current_user_id,
        },
      });
    },
  });
};
