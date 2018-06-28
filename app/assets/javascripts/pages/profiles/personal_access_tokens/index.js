import DueDateSelectors from '~/due_date_select';
import multiProjectSelect from '~/project_select_multi';

document.addEventListener('DOMContentLoaded', () => {
  new DueDateSelectors(); // eslint-disable-line no-new
  multiProjectSelect();
});
