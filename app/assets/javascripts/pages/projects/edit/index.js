import initSettingsPanels from '~/settings_panels';
import setupProjectEdit from '~/project_edit';

export default () => {
  setupProjectEdit();
  // Initialize expandable settings panels
  initSettingsPanels();
};
