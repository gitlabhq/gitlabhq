/* eslint-disable no-new */
import initSettingsPanels from '~/settings_panels';
import setupProjectEdit from '~/project_edit';
import initConfirmDangerModal from '~/confirm_danger_modal';
import initProjectLoadingSpinner from '../shared/save_project_loader';
import projectAvatar from '../shared/project_avatar';
import initProjectPermissionsSettings from '../shared/permissions';

document.addEventListener('DOMContentLoaded', () => {
  initProjectLoadingSpinner();
  setupProjectEdit();
  // Initialize expandable settings panels
  initSettingsPanels();
  projectAvatar();
  initProjectPermissionsSettings();
  initConfirmDangerModal();
});
