import initSettingsPanels from '~/settings_panels';
import projectSelect from '~/project_select';
import selfMonitor from '~/self_monitor';
import maintenanceModeSettings from '~/maintenance_mode_settings';

document.addEventListener('DOMContentLoaded', () => {
  selfMonitor();
  maintenanceModeSettings();
  // Initialize expandable settings panels
  initSettingsPanels();
  projectSelect();
});
