import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { availableGraphQLGroupActions } from './utils';

export const formatGraphQLGroup = (
  { id, fullName, parent, maxAccessLevel: accessLevel, hasChildren, children, fullPath, ...group },
  callback = () => {},
) => {
  const baseGroup = {
    ...group,
    id: getIdFromGraphQLId(id),
    avatarLabel: fullName,
    fullName,
    parent: parent?.id || null,
    accessLevel,
    availableActions: availableGraphQLGroupActions(group),
    children: children?.length ? children.map((child) => formatGraphQLGroup(child, callback)) : [],
    childrenLoading: false,
    hasChildren: Boolean(hasChildren),
    fullPath,
    relativeWebUrl: joinPaths('/', gon.relative_url_root, fullPath),
  };

  return {
    ...baseGroup,
    ...callback(baseGroup),
  };
};

export const formatGraphQLGroups = (groups, callback = () => {}) =>
  groups.map((group) => formatGraphQLGroup(group, callback));
