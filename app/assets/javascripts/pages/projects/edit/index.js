import { PROJECT_BADGE } from '~/badges/constants';
import initSettingsPanels from '~/settings_panels';
import setupTransferEdit from '~/transfer_edit';
import initConfirmDangerModal from '~/confirm_danger_modal';
import mountBadgeSettings from '~/pages/shared/mount_badge_settings';
import dirtySubmitFactory from '~/dirty_submit/dirty_submit_factory';
import initFilePickers from '~/file_pickers';
import initProjectLoadingSpinner from '../shared/save_project_loader';
import initProjectPermissionsSettings from '../shared/permissions';

document.addEventListener('DOMContentLoaded', () => {
  initFilePickers();
  initConfirmDangerModal();
  initSettingsPanels();
  mountBadgeSettings(PROJECT_BADGE);

  initProjectLoadingSpinner();
  initProjectPermissionsSettings();
  setupTransferEdit('.js-project-transfer-form', 'select.select2');

  dirtySubmitFactory(
    document.querySelectorAll(
      '.js-general-settings-form, .js-mr-settings-form, .js-mr-approvals-form',
    ),
  );
});
