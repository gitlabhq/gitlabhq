import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

import { SNIPPET_LEVELS_MAP, SNIPPET_VISIBILITY_PRIVATE } from '~/snippets/constants';
import Translate from '~/vue_shared/translate';

Vue.use(VueApollo);
Vue.use(Translate);

export default function appFactory(el, Component) {
  if (!el) {
    return false;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(
      {},
      {
        batchMax: 1,
        assumeImmutableResults: true,
      },
    ),
  });

  const {
    visibilityLevels = '[]',
    selectedLevel,
    multipleLevelsRestricted,
    reportAbusePath,
    ...restDataset
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      visibilityLevels: JSON.parse(visibilityLevels),
      selectedLevel: SNIPPET_LEVELS_MAP[selectedLevel] ?? SNIPPET_VISIBILITY_PRIVATE,
      multipleLevelsRestricted: 'multipleLevelsRestricted' in el.dataset,
      reportAbusePath,
    },
    render(createElement) {
      return createElement(Component, {
        props: {
          ...restDataset,
        },
      });
    },
  });
}
