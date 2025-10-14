import leaveByUrl from '~/namespaces/leave_by_url';
import { initGroupsShowApp } from '~/groups/show';
import { initGroupReadme } from '~/groups/init_group_readme';
import initReadMore from '~/read_more';
import InitMoreActionsDropdown from '~/groups_projects/init_more_actions_dropdown';
import initGroupDetails from '../shared/group_details';

initGroupDetails();
initGroupsShowApp();
initReadMore();
initGroupReadme();
InitMoreActionsDropdown();
leaveByUrl('group');
