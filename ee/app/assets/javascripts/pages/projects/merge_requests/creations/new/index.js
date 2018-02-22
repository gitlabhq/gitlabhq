import '~/pages/projects/merge_requests/creations/new/index';
import UserCallout from '~/user_callout';
import initForm from '../../shared/init_form';

document.addEventListener('DOMContentLoaded', () => {
  initForm();
  return new UserCallout();
});
