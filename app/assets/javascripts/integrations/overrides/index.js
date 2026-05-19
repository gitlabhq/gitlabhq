import Vue from 'vue';
import VueApollo from 'vue-apollo';
import ExclusionsList from '~/integrations/beyond_identity/components/exclusions_list.vue';
import createDefaultClient from '~/lib/graphql';
import IntegrationOverrides from './components/integration_overrides.vue';

export const initIntegrationOverrides = () => {
  const el = document.querySelector('.js-vue-integration-overrides');

  if (!el) {
    return null;
  }

  const { editPath, overridesPath } = el.dataset;

  return new Vue({
    el,
    name: 'IntegrationOverridesRoot',
    provide: {
      editPath,
    },
    render(createElement) {
      return createElement(IntegrationOverrides, {
        props: {
          overridesPath,
        },
      });
    },
  });
};

export const initBeyondIdentityExclusions = () => {
  const el = document.querySelector('.js-vue-beyond-identity-exclusions');

  if (!el) {
    return null;
  }

  const { editPath } = el.dataset;

  return new Vue({
    el,
    name: 'IntegrationsExclusionsListRoot',

    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide: {
      editPath,
    },
    render(createElement) {
      return createElement(ExclusionsList);
    },
  });
};
