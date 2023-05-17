import initVariableList from '~/ci/ci_variable_list';
import initSearchSettings from '~/search_settings';
import initSettingsPanels from '~/settings_panels';

initVariableList('js-instance-variables');
// Initialize expandable settings panels
initSettingsPanels();
initSearchSettings();
