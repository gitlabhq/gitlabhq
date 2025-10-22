import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_GROUP, TYPENAME_PROJECT } from '~/graphql_shared/constants';
import { ACCESS_LEVEL_NO_ACCESS_INTEGER } from '~/access_level/constants';
import { FEATURABLE_DISABLED } from '~/featurable/constants';
import { LIST_ITEM_TYPE_GROUP } from '~/vue_shared/components/nested_groups_projects_list/constants';

const formatSubgroupsAndProjects = (item) => {
  const baseItem = {
    type: item.type,
    name: item.name,
    fullPath: item.full_path,
    editPath: item.edit_path,
    archived: item.archived,
    descriptionHtml: item.markdown_description,
    visibility: item.visibility,
    createdAt: item.created_at,
    updatedAt: item.updated_at,
    avatarUrl: item.avatar_url,
    markedForDeletion: item.marked_for_deletion,
    isSelfDeletionInProgress: item.is_self_deletion_in_progress,
    isSelfDeletionScheduled: item.is_self_deletion_scheduled,
    permanentDeletionDate: item.permanent_deletion_date,
    maxAccessLevel: {
      integerValue: item.permission_integer ?? ACCESS_LEVEL_NO_ACCESS_INTEGER,
    },
    webUrl: item.web_url,
  };

  if (item.type === LIST_ITEM_TYPE_GROUP) {
    const childrenCount = item.children_count ?? 0;

    return {
      ...baseItem,
      __typename: TYPENAME_GROUP,
      id: convertToGraphQLId(TYPENAME_GROUP, item.id),
      fullName: item.full_name,
      userPermissions: {
        archiveGroup: item.can_archive,
        canLeave: item.can_leave,
        removeGroup: item.can_remove,
        viewEditPage: item.can_edit,
      },
      groupMembersCount: item.group_members_count ?? null,
      isLinkedToSubscription: item.is_linked_to_subscription,
      parent: {
        id: item.parent_id,
      },
      descendantGroupsCount: item.subgroup_count ?? null,
      projectsCount: item.project_count ?? null,
      children: item.children?.length ? item.children.map(formatSubgroupsAndProjects) : [],
      childrenCount,
      hasChildren: childrenCount > 0,
    };
  }

  return {
    ...baseItem,
    __typename: TYPENAME_PROJECT,
    id: convertToGraphQLId(TYPENAME_PROJECT, item.id),
    nameWithNamespace: item.full_name,
    lastActivityAt: item.last_activity_at,
    starCount: item.star_count,
    userPermissions: {
      archiveProject: item.can_archive,
      removeProject: item.can_remove,
      viewEditPage: item.can_edit,
    },
    // All properties below are not yet supported by `/children.json` endpoint
    // We set them to defaults so that we don't get Apollo errors when
    // formatting as GraphQL.
    group: null,
    topics: [],
    isCatalogResource: false,
    exploreCatalogPath: '',
    isPublished: false,
    pipeline: null,
    forksCount: 0,
    openMergeRequestsCount: 0,
    openIssuesCount: 0,
    mergeRequestsAccessLevel: {
      stringValue: FEATURABLE_DISABLED,
    },
    issuesAccessLevel: {
      stringValue: FEATURABLE_DISABLED,
    },
    forkingAccessLevel: {
      stringValue: FEATURABLE_DISABLED,
    },
  };
};

export const resolvers = (endpoint) => ({
  Query: {
    async subgroupsAndProjects(_, { active, search: filter, sort, parentId, page }) {
      const { data, headers } = await axios.get(endpoint, {
        params: { active, filter, sort, parent_id: parentId, page },
      });

      const normalizedHeaders = normalizeHeaders(headers);
      const pageInfo = {
        ...parseIntPagination(normalizedHeaders),
        __typename: 'LocalPageInfo',
      };

      return {
        nodes: data.map(formatSubgroupsAndProjects),
        pageInfo,
      };
    },
  },
});
