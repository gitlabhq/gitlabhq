import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import { ACCESS_LEVELS_STRING_TO_INTEGER } from '~/access_level/constants';

export const formatGroupForGraphQLResolver = (group) => ({
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
  markedForDeletionOn: group.marked_for_deletion_on,
  userPermissions: {
    canLeave: group.can_leave,
    removeGroup: group.can_remove,
    viewEditPage: group.can_edit,
  },
  webUrl: group.web_url,
  groupMembersCount: group.group_members_count,
  isLinkedToSubscription: group.is_linked_to_subscription,
  permanentDeletionDate: group.permanent_deletion_date,
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
  children: group.children?.length ? group.children.map(formatGroupForGraphQLResolver) : [],
  childrenCount: group.subgroup_count,
});
