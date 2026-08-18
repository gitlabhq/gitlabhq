import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import ProjectGeneralSettings from './components/project_general_settings.vue';

Vue.use(VueApollo);

export default () => {
  const el = document.getElementById('js-project-general-settings');

  if (!el) {
    return null;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const {
    projectId,
    projectName,
    projectDescription,
    projectAvatarUrl,
    projectAvatarRemovable,
    projectTopics,
    maxDescriptionLength,
    formAction,
    organizationId,
    canEditRepositorySizeLimit,
    repositorySizeLimitValue,
    repositorySizeLimitHelpText,
    showRepositorySizeLimitCta,
    servicePingSettingsPath,
    externalAuthorizationEnabled,
    externalAuthorizationClassificationLabel,
    externalAuthorizationHelpText,
  } = el.dataset;

  // Parse topics from JSON
  let parsedTopics = [];
  try {
    const topicsArray = JSON.parse(projectTopics || '[]');
    parsedTopics = topicsArray.map((name, index) => ({
      id: index,
      name,
    }));
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(e);
  }

  return new Vue({
    el,
    name: 'ProjectGeneralSettingsRoot',
    apolloProvider,
    render(createElement) {
      return createElement(ProjectGeneralSettings, {
        props: {
          projectId: parseInt(projectId, 10),
          projectName,
          projectDescription: projectDescription || '',
          projectAvatarUrl: projectAvatarUrl || '',
          projectAvatarRemovable: parseBoolean(projectAvatarRemovable),
          projectTopics: parsedTopics,
          maxDescriptionLength: parseInt(maxDescriptionLength, 10),
          formAction,
          organizationId,
          canEditRepositorySizeLimit: parseBoolean(canEditRepositorySizeLimit),
          repositorySizeLimitValue: repositorySizeLimitValue
            ? parseInt(repositorySizeLimitValue, 10)
            : null,
          repositorySizeLimitHelpText: repositorySizeLimitHelpText || '',
          showRepositorySizeLimitCta: parseBoolean(showRepositorySizeLimitCta),
          servicePingSettingsPath: servicePingSettingsPath || '',
          externalAuthorizationEnabled: parseBoolean(externalAuthorizationEnabled),
          externalAuthorizationClassificationLabel: externalAuthorizationClassificationLabel || '',
          externalAuthorizationHelpText: externalAuthorizationHelpText || '',
        },
      });
    },
  });
};
