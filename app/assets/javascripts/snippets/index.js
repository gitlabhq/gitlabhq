import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Translate from '~/vue_shared/translate';
import createDefaultClient from '~/lib/graphql';

import { SNIPPET_LEVELS_MAP, SNIPPET_VISIBILITY_PRIVATE } from '~/snippets/constants';

Vue.use(VueApollo);
Vue.use(Translate);

function appFactory(el, Component) {
  if (!el) {
    return false;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient({}, { batchMax: 1 }),
  });

  const {
    visibilityLevels = '[]',
    selectedLevel,
    multipleLevelsRestricted,
    ...restDataset
  } = el.dataset;

  apolloProvider.clients.defaultClient.cache.writeData({
    data: {
      visibilityLevels: JSON.parse(visibilityLevels),
      selectedLevel: SNIPPET_LEVELS_MAP[selectedLevel] ?? SNIPPET_VISIBILITY_PRIVATE,
      multipleLevelsRestricted: 'multipleLevelsRestricted' in el.dataset,
    },
  });

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(Component, {
        props: {
          ...restDataset,
        },
      });
    },
  });
}

export const SnippetShowInit = () => {
  import('./components/show.vue')
    .then(({ default: SnippetsShow }) => {
      appFactory(document.getElementById('js-snippet-view'), SnippetsShow);
    })
    .catch(() => {});
};

export const SnippetEditInit = () => {
  import('./components/edit.vue')
    .then(({ default: SnippetsEdit }) => {
      appFactory(document.getElementById('js-snippet-edit'), SnippetsEdit);
    })
    .catch(() => {});
};
