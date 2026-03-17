import leaveByUrl, { NAMESPACE_TYPES } from '~/namespaces/leave_by_url';
import { initGroupsShowApp } from '~/groups/show';
import { initGroupReadme } from '~/groups/init_group_readme';
import initReadMore from '~/read_more';
import { initGroupActions } from '~/groups/show/actions';
import initGroupDetails from '../shared/group_details';

initGroupDetails();
initGroupsShowApp();
initReadMore();
initGroupReadme();
initGroupActions();
leaveByUrl(NAMESPACE_TYPES.GROUP);
