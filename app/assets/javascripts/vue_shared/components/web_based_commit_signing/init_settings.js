import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import WebBasedCommitSigningSettings from './settings.vue';

export const initWebBasedCommitSigningSettings = (el, dataset, isGroupLevel) => {
  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const provide = {
    groupSettingsRepositoryPath: dataset.groupSettingsRepositoryPath,
    fullPath: dataset.fullPath,
    levelId: parseInt(dataset.levelId, 10),
  };

  const props = {
    initialValue: parseBoolean(dataset.webBasedCommitSigningEnabled),
    canAdminGroup: parseBoolean(dataset.canAdminGroup),
    isGroupLevel,
    ...(isGroupLevel
      ? {}
      : {
          groupWebBasedCommitSigningEnabled: parseBoolean(
            dataset.groupWebBasedCommitSigningEnabled,
          ),
        }),
  };

  return new Vue({
    el,
    name: 'WebBasedCommitSigningSettings',
    apolloProvider,
    provide,
    render(createElement) {
      return createElement(WebBasedCommitSigningSettings, {
        props,
      });
    },
  });
};
