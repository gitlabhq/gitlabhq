import initSettingsPanels from '~/settings_panels';
import projectSelect from '~/project_select';
import selfMonitor from '~/self_monitor';

document.addEventListener('DOMContentLoaded', () => {
  selfMonitor();
  // Initialize expandable settings panels
  initSettingsPanels();
  projectSelect();
});
