import { PROJECT_BADGE } from '~/badges/constants';
import initSettingsPanels from '~/settings_panels';
import setupTransferEdit from '~/transfer_edit';
import initConfirmDangerModal from '~/confirm_danger_modal';
import mountBadgeSettings from '~/pages/shared/mount_badge_settings';
import dirtySubmitFactory from '~/dirty_submit/dirty_submit_factory';
import initFilePickers from '~/file_pickers';
import initProjectLoadingSpinner from '../shared/save_project_loader';
import initProjectPermissionsSettings from '../shared/permissions';
import initProjectDeleteButton from '~/projects/project_delete_button';
import UserCallout from '~/user_callout';
import initServiceDesk from '~/projects/settings_service_desk';

document.addEventListener('DOMContentLoaded', () => {
  initFilePickers();
  initConfirmDangerModal();
  initSettingsPanels();
  initProjectDeleteButton();
  mountBadgeSettings(PROJECT_BADGE);

  new UserCallout({ className: 'js-service-desk-callout' }); // eslint-disable-line no-new
  initServiceDesk();

  initProjectLoadingSpinner();
  initProjectPermissionsSettings();
  setupTransferEdit('.js-project-transfer-form', 'select.select2');

  dirtySubmitFactory(
    document.querySelectorAll(
      '.js-general-settings-form, .js-mr-settings-form, .js-mr-approvals-form',
    ),
  );
});
