import { GROUP_BADGE } from '~/badges/constants';
import initDatePickers from '~/behaviors/date_picker';
import dirtySubmitFactory from '~/dirty_submit/dirty_submit_factory';
import initFilePickers from '~/file_pickers';
import { initCheckboxControlledInput } from '~/pages/admin/application_settings/account_and_limits';
import initTransferGroupForm from '~/groups/init_transfer_group_form';
import { initGroupSelects } from '~/vue_shared/components/entity_select/init_group_selects';
import { initProjectSelects } from '~/vue_shared/components/entity_select/init_project_selects';
import { initCascadingSettingsLockTooltips } from '~/namespaces/cascading_settings';
import mountBadgeSettings from '~/pages/shared/mount_badge_settings';
import initSearchSettings from '~/search_settings';
import initSettingsPanels from '~/settings_panels';
import initConfirmDanger from '~/init_confirm_danger';
import { initGroupSettingsReadme } from '~/groups/settings/init_group_settings_readme';
import initArchiveSettings from '~/groups_projects/archive';
import initUnarchiveSettings from '~/groups_projects/unarchive';
import { initGroupDeleteButton } from '~/groups/group_delete_button';

initFilePickers();
initConfirmDanger();
initSettingsPanels();
initTransferGroupForm();
dirtySubmitFactory(document.querySelectorAll('.js-general-settings-form'));
mountBadgeSettings(GROUP_BADGE);

// Initialize Subgroups selector
initGroupSelects();

// Initialize project selectors
initProjectSelects();

initSearchSettings();
initCascadingSettingsLockTooltips();

initCheckboxControlledInput(
  'group_enforce_granular_tokens',
  'group_granular_tokens_enforced_after',
  'group_granular_tokens_enforced_after_error',
);

initDatePickers();

initGroupSettingsReadme();
initArchiveSettings();
initUnarchiveSettings();
initGroupDeleteButton();
