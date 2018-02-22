import '~/pages/projects/merge_requests/creations/new/index';
import UserCallout from '~/user_callout';
import initForm from '../../shared/init_form';

export default () => {
  initForm();
  return new UserCallout();
};
