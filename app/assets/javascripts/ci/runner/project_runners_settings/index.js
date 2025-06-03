import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { showAlertFromLocalStorage } from '../local_storage_alert/show_alert_from_local_storage';
import ProjectRunnersSettingsApp from './project_runners_settings_app.vue';

Vue.use(VueApollo);

export const initProjectRunnersSettings = (selector = '#js-project-runners-settings') => {
  showAlertFromLocalStorage();

  const el = document.querySelector(selector);

  if (!el) {
    return null;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const {
    canCreateRunner,
    canCreateRunnerForGroup,
    groupRunnersPath,
    allowRegistrationToken,
    registrationToken,
    newProjectRunnerPath,
    projectFullPath,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      canCreateRunnerForGroup: parseBoolean(canCreateRunnerForGroup),
      groupRunnersPath,
    },
    render(h) {
      return h(ProjectRunnersSettingsApp, {
        props: {
          canCreateRunner: parseBoolean(canCreateRunner),
          allowRegistrationToken: parseBoolean(allowRegistrationToken),
          registrationToken,
          newProjectRunnerPath,
          projectFullPath,
        },
      });
    },
  });
};
