/* eslint-disable no-new */
import AbuseReports from './abuse_reports';
import UsersSelect from '~/users_select';

document.addEventListener('DOMContentLoaded', () => {
  new AbuseReports();
  new UsersSelect();
});
