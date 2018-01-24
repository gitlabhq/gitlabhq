import initSettingsPanels from '~/settings_panels';
import SecretValues from '~/behaviors/secret_values';

export default function () {
  // Initialize expandable settings panels
  initSettingsPanels();
  const runnerToken = document.querySelector('.js-secret-runner-token');
  if (runnerToken) {
    const runnerTokenSecretValue = new SecretValues(runnerToken);
    runnerTokenSecretValue.init();
  }

  const secretVariableTable = document.querySelector('.js-secret-variable-table');
  if (secretVariableTable) {
    const secretVariableTableValues = new SecretValues(secretVariableTable);
    secretVariableTableValues.init();
  }
}
