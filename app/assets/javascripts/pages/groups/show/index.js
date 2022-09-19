import leaveByUrl from '~/namespaces/leave_by_url';
import { initGroupOverviewTabs } from '~/groups/init_overview_tabs';
import initGroupDetails from '../shared/group_details';

leaveByUrl('group');
initGroupDetails();
initGroupOverviewTabs();
