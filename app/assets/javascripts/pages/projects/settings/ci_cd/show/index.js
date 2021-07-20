import initArtifactsSettings from '~/artifacts_settings';
import SecretValues from '~/behaviors/secret_values';
import initSettingsPipelinesTriggers from '~/ci_settings_pipeline_triggers';
import initVariableList from '~/ci_variable_list';
import initDeployFreeze from '~/deploy_freeze';
import registrySettingsApp from '~/packages_and_registries/settings/project/registry_settings_bundle';
import { initRunnerAwsDeployments } from '~/pages/shared/mount_runner_aws_deployments';
import { initInstallRunner } from '~/pages/shared/mount_runner_instructions';
import initSharedRunnersToggle from '~/projects/settings/mount_shared_runners_toggle';
import initSettingsPanels from '~/settings_panels';
import { initTokenAccess } from '~/token_access';

document.addEventListener('DOMContentLoaded', () => {
  // Initialize expandable settings panels
  initSettingsPanels();

  const runnerToken = document.querySelector('.js-secret-runner-token');
  if (runnerToken) {
    const runnerTokenSecretValue = new SecretValues({
      container: runnerToken,
    });
    runnerTokenSecretValue.init();
  }

  initVariableList();

  // hide extra auto devops settings based checkbox state
  const autoDevOpsExtraSettings = document.querySelector('.js-extra-settings');
  const instanceDefaultBadge = document.querySelector('.js-instance-default-badge');
  document.querySelector('.js-toggle-extra-settings').addEventListener('click', (event) => {
    const { target } = event;
    if (instanceDefaultBadge) instanceDefaultBadge.style.display = 'none';
    autoDevOpsExtraSettings.classList.toggle('hidden', !target.checked);
  });

  registrySettingsApp();
  initDeployFreeze();

  initSettingsPipelinesTriggers();
  initArtifactsSettings();
  initSharedRunnersToggle();
  initInstallRunner();
  initRunnerAwsDeployments();
  initTokenAccess();
});
