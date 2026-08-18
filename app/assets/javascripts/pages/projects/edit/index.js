import { PROJECT_BADGE } from '~/badges/constants';
import initConfirmDanger from '~/init_confirm_danger';
import dirtySubmitFactory from '~/dirty_submit/dirty_submit_factory';
import initFilePickers from '~/file_pickers';
import mountBadgeSettings from '~/pages/shared/mount_badge_settings';
import initProjectDeleteButton from '~/projects/project_delete_button';
import initServiceDesk from '~/projects/settings_service_desk';
import initTransferProjectForm from '~/projects/settings/init_transfer_project_form';
import initSearchSettings from '~/search_settings';
import initSettingsPanels from '~/settings_panels';
import UserCallout from '~/user_callout';
import { initProjectSelects } from '~/vue_shared/components/entity_select/init_project_selects';
import initPruneObjectsButton from '~/projects/prune_objects_button';
import initArchiveSettings from '~/groups_projects/archive';
import initUnarchiveSettings from '~/groups_projects/unarchive';
import initTopicsTokenSelector from '~/projects/settings/topics';
import { initProjectNameValidation } from '~/projects/project_name_validation';
import mountProjectGeneralSettings from '~/projects/settings/mount_project_general_settings';
import { initProjectPermissionsSettings } from '../shared/permissions/init_project_permissions_settings';
import initGitlabDuoSettings from '../shared/permissions/gitlab_duo_settings';
import initProjectLoadingSpinner from '../shared/save_project_loader';

initFilePickers();
initConfirmDanger();
initSettingsPanels();
initProjectDeleteButton();
initPruneObjectsButton();
mountBadgeSettings(PROJECT_BADGE);

new UserCallout({ className: 'js-service-desk-callout' }); // eslint-disable-line no-new
initServiceDesk();

initProjectLoadingSpinner();
initProjectPermissionsSettings();
initGitlabDuoSettings();
initTransferProjectForm();

initSearchSettings();
initArchiveSettings();
initUnarchiveSettings();
initProjectSelects();

// Mount the general settings Vue app (includes topics selector) when the
// `project_general_settings_vue` feature flag renders its mount point.
// Otherwise initialize the legacy server-rendered form.
if (mountProjectGeneralSettings()) {
  dirtySubmitFactory(document.querySelectorAll('.js-mr-settings-form'));
} else {
  initTopicsTokenSelector();
  initProjectNameValidation();
  dirtySubmitFactory(document.querySelectorAll('.js-general-settings-form, .js-mr-settings-form'));
}
