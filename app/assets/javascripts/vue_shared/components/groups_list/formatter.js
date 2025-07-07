import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { availableGraphQLGroupActions } from './utils';

export const formatGraphQLGroups = (groups, callback = () => {}) =>
  groups.map(
    ({
      id,
      fullName,
      parent,
      maxAccessLevel: accessLevel,
      descendantGroupsCount,
      children,
      ...group
    }) => {
      const baseGroup = {
        ...group,
        id: getIdFromGraphQLId(id),
        avatarLabel: fullName,
        fullName,
        parent: parent?.id || null,
        accessLevel,
        availableActions: availableGraphQLGroupActions(group),
        descendantGroupsCount,
        children: children?.length ? formatGraphQLGroups(children, callback) : [],
        childrenLoading: false,
        hasChildren: Boolean(descendantGroupsCount),
      };

      return {
        ...baseGroup,
        ...callback(baseGroup),
      };
    },
  );
