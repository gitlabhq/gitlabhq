import initSettingsPanels from '~/settings_panels';
import SecretValues from '~/behaviors/secret_values';
import AjaxVariableList from '~/ci_variable_list/ajax_variable_list';
import registrySettingsApp from '~/registry/settings/registry_settings_bundle';

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

  const variableListEl = document.querySelector('.js-ci-variable-list-section');
  // eslint-disable-next-line no-new
  new AjaxVariableList({
    container: variableListEl,
    saveButton: variableListEl.querySelector('.js-ci-variables-save-button'),
    errorBox: variableListEl.querySelector('.js-ci-variable-error-box'),
    saveEndpoint: variableListEl.dataset.saveEndpoint,
    maskableRegex: variableListEl.dataset.maskableRegex,
  });

  // hide extra auto devops settings based checkbox state
  const autoDevOpsExtraSettings = document.querySelector('.js-extra-settings');
  const instanceDefaultBadge = document.querySelector('.js-instance-default-badge');
  document.querySelector('.js-toggle-extra-settings').addEventListener('click', event => {
    const { target } = event;
    if (instanceDefaultBadge) instanceDefaultBadge.style.display = 'none';
    autoDevOpsExtraSettings.classList.toggle('hidden', !target.checked);
  });

  registrySettingsApp();
});
