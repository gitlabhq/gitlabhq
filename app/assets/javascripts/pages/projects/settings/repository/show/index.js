import initSettingsPanels from '~/settings_panels';
import initDeployKeys from '~/deploy_keys';

document.addEventListener('DOMContentLoaded', () => {
  initDeployKeys();
  initSettingsPanels();
});
