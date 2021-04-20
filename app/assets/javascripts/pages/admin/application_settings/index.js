import initVariableList from '~/ci_variable_list';
import projectSelect from '~/project_select';
import initSearchSettings from '~/search_settings';
import selfMonitor from '~/self_monitor';
import initSettingsPanels from '~/settings_panels';

initVariableList('js-instance-variables');
selfMonitor();
// Initialize expandable settings panels
initSettingsPanels();
projectSelect();
initSearchSettings();
