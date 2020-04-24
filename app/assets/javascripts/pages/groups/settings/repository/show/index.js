import initSettingsPanels from '~/settings_panels';
import DueDateSelectors from '~/due_date_select';

document.addEventListener('DOMContentLoaded', () => {
  // Initialize expandable settings panels
  initSettingsPanels();

  new DueDateSelectors(); // eslint-disable-line no-new
});
