import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import initIntegrationOverrides from '~/integrations/overrides';
import ExclusionsList from '~/integrations/beyond_identity/components/exclusions_list.vue';

const initBeyondIdentityExclusions = () => {
  const el = document.querySelector('.js-vue-beyond-identity-exclusions');

  if (!el) {
    return null;
  }

  const { editPath } = el.dataset;

  return new Vue({
    el,

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

initBeyondIdentityExclusions();

initIntegrationOverrides();
