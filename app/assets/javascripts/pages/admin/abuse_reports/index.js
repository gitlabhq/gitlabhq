/* eslint-disable no-new */
import UsersSelect from '~/users_select';
import AbuseReports from './abuse_reports';

document.addEventListener('DOMContentLoaded', () => {
  new AbuseReports();
  new UsersSelect();
});
