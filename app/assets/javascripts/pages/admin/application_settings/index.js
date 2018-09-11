import initSettingsPanels from '~/settings_panels';
import projectSelect from '~/project_select';

document.addEventListener('DOMContentLoaded', () => {
  // Initialize expandable settings panels
  initSettingsPanels();
  projectSelect();
});
