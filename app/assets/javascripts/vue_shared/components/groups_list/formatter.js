import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { joinPaths } from '~/lib/utils/url_utility';
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
      fullPath,
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
        fullPath,
        relativeWebUrl: joinPaths('/', gon.relative_url_root, fullPath),
      };

      return {
        ...baseGroup,
        ...callback(baseGroup),
      };
    },
  );
