import { initNewResourceDropdown } from '~/vue_shared/components/new_resource_dropdown/init_new_resource_dropdown';
import { RESOURCE_TYPE_MILESTONE } from '~/vue_shared/components/new_resource_dropdown/constants';
import searchUserGroupsAndProjects from '~/vue_shared/components/new_resource_dropdown/graphql/search_user_groups_and_projects.query.graphql';
import InitMoreActionsDropdown from '~/milestones/init_more_actions_dropdown';

initNewResourceDropdown({
  resourceType: RESOURCE_TYPE_MILESTONE,
  query: searchUserGroupsAndProjects,
  extractProjects: (data) => [
    ...(data?.user?.groups?.nodes ?? []),
    ...(data?.projects?.nodes ?? []),
  ],
});
InitMoreActionsDropdown();
