import '~/pages/projects/settings/repository/show/index';
import UsersSelect from '~/users_select';
import UserCallout from '~/user_callout';

document.addEventListener('DOMContentLoaded', () => {
  new UsersSelect(); // eslint-disable-line no-new
  new UserCallout(); // eslint-disable-line no-new
});
