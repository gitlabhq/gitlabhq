import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';

import {
  VISIBILITY_LEVEL_PRIVATE_STRING,
  VISIBILITY_LEVELS_INTEGER_TO_STRING,
} from '~/visibility_level/constants';
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
      },
    ),
  });

  const {
    visibilityLevels = '[]',
    selectedLevel,
    multipleLevelsRestricted,
    canReportSpam,
    reportAbusePath,
    ...restDataset
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      visibilityLevels: JSON.parse(visibilityLevels),
      selectedLevel:
        VISIBILITY_LEVELS_INTEGER_TO_STRING[selectedLevel] ?? VISIBILITY_LEVEL_PRIVATE_STRING,
      multipleLevelsRestricted: 'multipleLevelsRestricted' in el.dataset,
      reportAbusePath,
      canReportSpam,
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
