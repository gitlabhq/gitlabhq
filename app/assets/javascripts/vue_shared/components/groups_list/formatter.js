import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { availableGraphQLGroupActions } from './utils';

export const formatGraphQLGroups = (groups, callback = () => {}) =>
  groups.map(
    ({
      id,
      fullName,
      webUrl,
      parent,
      markedForDeletion,
      isSelfDeletionInProgress,
      maxAccessLevel: accessLevel,
      userPermissions,
      descendantGroupsCount,
      children,
      ...group
    }) => {
      const baseGroup = {
        ...group,
        id: getIdFromGraphQLId(id),
        avatarLabel: fullName,
        fullName,
        webUrl,
        parent: parent?.id || null,
        markedForDeletion,
        isSelfDeletionInProgress,
        accessLevel,
        availableActions: availableGraphQLGroupActions({
          userPermissions,
          markedForDeletion,
          isSelfDeletionInProgress,
        }),
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
