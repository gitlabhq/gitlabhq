import DueDateSelectors from '~/due_date_select';
import projectMultiSelect from '~/project_multi_select';

document.addEventListener('DOMContentLoaded', () => {
  new DueDateSelectors(); // eslint-disable-line no-new
  projectMultiSelect();
});
