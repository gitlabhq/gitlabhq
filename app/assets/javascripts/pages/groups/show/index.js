import leaveByUrl from '~/namespaces/leave_by_url';
import initGroupDetails from '../shared/group_details';

document.addEventListener('DOMContentLoaded', () => {
  leaveByUrl('group');
  initGroupDetails();
});
