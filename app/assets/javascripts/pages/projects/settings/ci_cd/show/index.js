import initSettingsPanels from '~/settings_panels';
import SecretValues from '~/behaviors/secret_values';
import AjaxVariableList from '~/ci_variable_list/ajax_variable_list';
import AutoDevopsForm from './ci_autodevops_form';

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
    saveButton: variableListEl.querySelector('.js-secret-variables-save-button'),
    errorBox: variableListEl.querySelector('.js-ci-variable-error-box'),
    saveEndpoint: variableListEl.dataset.saveEndpoint,
  });

  // eslint-disable-next-line no-new
  new AutoDevopsForm('#js-general-pipeline-settings');
});
