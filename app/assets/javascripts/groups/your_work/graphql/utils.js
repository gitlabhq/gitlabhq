import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import { ACCESS_LEVELS_STRING_TO_INTEGER } from '~/access_level/constants';

export const formatGroup = (group) => ({
  __typename: TYPENAME_GROUP,
  id: convertToGraphQLId(TYPENAME_GROUP, group.id),
  name: group.name,
  fullName: group.full_name,
  fullPath: group.relative_path,
  descriptionHtml: group.markdown_description,
  visibility: group.visibility,
  createdAt: group.created_at,
  updatedAt: group.updated_at,
  avatarUrl: group.avatar_url,
  userPermissions: {
    removeGroup: group.can_remove,
    viewEditPage: group.can_edit,
  },
  webUrl: group.relative_path,
  maxAccessLevel: {
    integerValue: group.permission
      ? ACCESS_LEVELS_STRING_TO_INTEGER[group.permission.toUpperCase()]
      : null,
  },
  parent: {
    id: group.parent_id,
  },
  descendantGroupsCount: group.subgroup_count,
  projectsCount: group.project_count,
  children: group.children ? group.children.map(formatGroup) : [],
  // Properties below are hard coded for now until API has been
  // updated to support these fields.
  organizationEditPath: '',
  groupMembersCount: 0,
  isLinkedToSubscription: false,
});
