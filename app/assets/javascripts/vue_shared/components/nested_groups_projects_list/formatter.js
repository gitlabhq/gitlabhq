import { formatGraphQLGroup } from '~/vue_shared/components/groups_list/formatter';
import { formatGraphQLProject } from '~/vue_shared/components/projects_list/formatter';
import { LIST_ITEM_TYPE_GROUP } from './constants';

export const formatGraphQLGroupsAndProjects = (
  items,
  groupsCallback = () => {},
  projectsCallback = () => {},
) => {
  return items.map((item) => {
    if (item.type === LIST_ITEM_TYPE_GROUP) {
      return {
        ...formatGraphQLGroup(item, groupsCallback),
        children: item.children?.length
          ? formatGraphQLGroupsAndProjects(item.children, groupsCallback, projectsCallback)
          : [],
      };
    }

    return formatGraphQLProject(item, projectsCallback);
  });
};
