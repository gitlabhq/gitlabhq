import { GROUP_BADGE } from '~/badges/constants';
import dirtySubmitFactory from '~/dirty_submit/dirty_submit_factory';
import initFilePickers from '~/file_pickers';
import initTransferGroupForm from '~/groups/init_transfer_group_form';
import { initGroupSelects } from '~/vue_shared/components/entity_select/init_group_selects';
import { initProjectSelects } from '~/vue_shared/components/entity_select/init_project_selects';
import { initCascadingSettingsLockPopovers } from '~/namespaces/cascading_settings';
import { initDormantUsersInputSection } from '~/pages/admin/application_settings/account_and_limits';
import mountBadgeSettings from '~/pages/shared/mount_badge_settings';
import initSearchSettings from '~/search_settings';
import initSettingsPanels from '~/settings_panels';
import initConfirmDanger from '~/init_confirm_danger';
import { initGroupSettingsReadme } from '~/groups/settings/init_group_settings_readme';

/**
 * Sets up logic inside "Dormant members" subsection:
 * - checkbox enables/disables additional input
 * - shows/hides an inline error on input validation
 */
function initDeactivateDormantMembersPeriodInputSection() {
  initDormantUsersInputSection(
    'group_remove_dormant_members',
    'group_remove_dormant_members_period',
    'group_remove_dormant_members_period_error',
  );
}

initDeactivateDormantMembersPeriodInputSection();
initFilePickers();
initConfirmDanger();
initSettingsPanels();
initTransferGroupForm();
dirtySubmitFactory(
  document.querySelectorAll('.js-general-settings-form, .js-general-permissions-form'),
);
mountBadgeSettings(GROUP_BADGE);

// Initialize Subgroups selector
initGroupSelects();

// Initialize project selectors
initProjectSelects();

initSearchSettings();
initCascadingSettingsLockPopovers();

initGroupSettingsReadme();
