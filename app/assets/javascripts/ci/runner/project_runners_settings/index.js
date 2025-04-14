import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import ProjectRunnersSettingsApp from './project_runners_settings_app.vue';

Vue.use(VueApollo);

export const initProjectRunnersSettings = (selector = '#js-project-runners-settings') => {
  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const {
    canCreateRunner,
    allowRegistrationToken,
    registrationToken,
    newProjectRunnerPath,
    groupFullPath,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    render(h) {
      return h(ProjectRunnersSettingsApp, {
        props: {
          canCreateRunner: parseBoolean(canCreateRunner),
          allowRegistrationToken: parseBoolean(allowRegistrationToken),
          registrationToken,
          newProjectRunnerPath,
          groupFullPath,
        },
      });
    },
  });
};
