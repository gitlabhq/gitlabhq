import initArtifactsSettings from '~/artifacts_settings';
import initVariablesMinimumOverrideRole from '~/ci/pipeline_variables_minimum_override_role';
import initSettingsPipelinesTriggers from '~/ci_settings_pipeline_triggers';
import initVariableList from '~/ci/ci_variable_list';
import initInheritedGroupCiVariables from '~/ci/inherited_ci_variables';
import initDeployFreeze from '~/deploy_freeze';
import initRefSwitcherBadges from '~/projects/settings/mount_ref_switcher_badges';
import initSettingsPanels from '~/settings_panels';
import { initJobTokenAccess } from '~/ci/job_token_access';
import { initCiSecureFiles } from '~/ci_secure_files';
import initDeployTokens from '~/deploy_tokens';
import { initProjectRunnersSettings } from '~/ci/runner/project_runners_settings/index';
import { initGeneralPipelinesOptions } from '~/ci_settings_general_pipeline';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

// Initialize expandable settings panels
initSettingsPanels();

initVariableList();
initInheritedGroupCiVariables();

// hide extra auto devops settings based checkbox state
const autoDevOpsExtraSettings = document.querySelector('.js-extra-settings');
const instanceDefaultBadge = document.querySelector('.js-instance-default-badge');
const extraSettingsToggle = document.querySelector('.js-toggle-extra-settings');

extraSettingsToggle?.addEventListener('click', (event) => {
  const { target } = event;
  if (instanceDefaultBadge) instanceDefaultBadge.style.display = 'none';
  autoDevOpsExtraSettings.classList.toggle('hidden', !target.checked);
});

initDeployTokens();
initDeployFreeze();
initSettingsPipelinesTriggers();
initArtifactsSettings();
initVariablesMinimumOverrideRole();

initRefSwitcherBadges();
initJobTokenAccess();
initCiSecureFiles();
initGeneralPipelinesOptions();

if (gon.features?.vue3MigrateAdminRunners) {
  (async () => {
    try {
      // eslint-disable-next-line no-shadow -- Override with Vue 3 app
      const { initProjectRunnersSettings } =
        await import('~/ci/runner/project_runners_settings/index?vue3');
      initProjectRunnersSettings();
      return;
    } catch (e) {
      Sentry.captureException(e);
    }

    initProjectRunnersSettings();
  })();
} else {
  initProjectRunnersSettings();
}
