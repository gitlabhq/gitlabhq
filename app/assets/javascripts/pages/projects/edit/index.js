import initSettingsPanels from '~/settings_panels';
import setupProjectEdit from '~/project_edit';
import ProjectNew from '../shared/project_new';
import projectAvatar from '../shared/project_avatar';
import initProjectPermissionsSettings from '../shared/permissions';

document.addEventListener('DOMContentLoaded', () => {
  new ProjectNew(); // eslint-disable-line no-new
  setupProjectEdit();
  // Initialize expandable settings panels
  initSettingsPanels();
  projectAvatar();
  initProjectPermissionsSettings();
});
