import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlToast } from '@gitlab/ui';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { showAlertFromLocalStorage } from '~/lib/utils/local_storage_alert';
import ProjectRunnersSettingsApp from './project_runners_settings_app.vue';

Vue.use(VueApollo);
Vue.use(GlToast);

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
    projectId,
    canCreateRunner,
    canCreateRunnerForGroup,
    groupRunnersPath,
    allowRegistrationToken,
    registrationToken,
    newProjectRunnerPath,
    projectFullPath,

    instanceRunnersEnabled,
    instanceRunnersDisabledAndUnoverridable,
    instanceRunnersUpdatePath,
    instanceRunnersGroupSettingsPath,
    groupName,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectId,
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

          instanceRunnersEnabled: parseBoolean(instanceRunnersEnabled),
          instanceRunnersDisabledAndUnoverridable: parseBoolean(
            instanceRunnersDisabledAndUnoverridable,
          ),
          instanceRunnersUpdatePath,
          instanceRunnersGroupSettingsPath,
          groupName,
        },
      });
    },
  });
};
