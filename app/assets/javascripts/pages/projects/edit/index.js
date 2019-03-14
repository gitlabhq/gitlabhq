import { PROJECT_BADGE } from '~/badges/constants';
import initSettingsPanels from '~/settings_panels';
import setupProjectEdit from '~/project_edit';
import initConfirmDangerModal from '~/confirm_danger_modal';
import mountBadgeSettings from '~/pages/shared/mount_badge_settings';
import initAvatarPicker from '~/avatar_picker';
import initProjectLoadingSpinner from '../shared/save_project_loader';
import initProjectPermissionsSettings from '../shared/permissions';

document.addEventListener('DOMContentLoaded', () => {
  initProjectLoadingSpinner();
  setupProjectEdit();
  // Initialize expandable settings panels
  initSettingsPanels();
  initAvatarPicker();
  initProjectPermissionsSettings();
  initConfirmDangerModal();
  mountBadgeSettings(PROJECT_BADGE);
});
