import initVariableList from '~/ci_variable_list';
import initSharedRunnersForm from '~/group_settings/mount_shared_runners';
import initSettingsPanels from '~/settings_panels';

// Initialize expandable settings panels
initSettingsPanels();

initSharedRunnersForm();
initVariableList();
