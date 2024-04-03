import { GlToast } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { createLocalState } from '../graphql/list/local_state';
import GroupRunnersApp from './group_runners_app.vue';

Vue.use(GlToast);
Vue.use(VueApollo);

export const initGroupRunners = (selector = '#js-group-runners') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const {
    allowRegistrationToken,
    registrationToken,
    runnerInstallHelpPage,
    newRunnerPath,
    groupId,
    groupFullPath,
    onlineContactTimeoutSecs,
    staleTimeoutSecs,
  } = el.dataset;

  const { cacheConfig, typeDefs, localMutations } = createLocalState();

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient({}, { cacheConfig, typeDefs }),
  });

  return new Vue({
    el,
    apolloProvider,
    provide: {
      runnerInstallHelpPage,
      localMutations,
      groupId,
      onlineContactTimeoutSecs: parseInt(onlineContactTimeoutSecs, 10),
      staleTimeoutSecs: parseInt(staleTimeoutSecs, 10),
    },
    render(h) {
      return h(GroupRunnersApp, {
        props: {
          groupFullPath,
          newRunnerPath,
          allowRegistrationToken: parseBoolean(allowRegistrationToken),
          registrationToken,
        },
      });
    },
  });
};
