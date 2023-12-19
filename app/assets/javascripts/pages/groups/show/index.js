import leaveByUrl from '~/namespaces/leave_by_url';
import { initGroupOverviewTabs } from '~/groups/init_overview_tabs';
import { initGroupReadme } from '~/groups/init_group_readme';
import initReadMore from '~/read_more';
import InitMoreActionsDropdown from '~/groups_projects/init_more_actions_dropdown';
import initGroupDetails from '../shared/group_details';

initGroupDetails();
initGroupOverviewTabs();
initReadMore();
initGroupReadme();
InitMoreActionsDropdown();
leaveByUrl('group');
