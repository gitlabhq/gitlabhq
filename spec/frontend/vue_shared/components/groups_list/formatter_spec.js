import organizationGroupsGraphQlResponse from 'test_fixtures/graphql/organizations/groups.query.graphql.json';
import dashboardGroupsResponse from 'test_fixtures/groups/dashboard/index.json';
import {
  formatGraphQLGroup,
  formatGraphQLGroups,
  formatGroupForGraphQLResolver,
} from '~/vue_shared/components/groups_list/formatter';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';

const {
  data: {
    organization: {
      groups: { nodes: organizationGroups },
    },
  },
} = organizationGroupsGraphQlResponse;

const itCorrectlyFormatsWithActions = (formattedGroup, mockGroup) => {
  expect(formattedGroup).toMatchObject({
    id: getIdFromGraphQLId(mockGroup.id),
    avatarLabel: mockGroup.fullName,
    fullName: mockGroup.fullName,
    parent: null,
    accessLevel: {
      integerValue: 50,
    },
    availableActions: ['copy-id', 'edit', 'restore', 'leave', 'delete-immediately'],
    children: [],
    childrenLoading: false,
    hasChildren: false,
    relativeWebUrl: `/gitlab/${mockGroup.fullPath}`,
    customProperty: mockGroup.fullName,
  });
};

const itCorrectlyFormatsWithoutActions = (formattedGroup, mockGroup) => {
  expect(formattedGroup).toMatchObject({
    id: getIdFromGraphQLId(mockGroup.id),
    avatarLabel: mockGroup.fullName,
    fullName: mockGroup.fullName,
    parent: null,
    accessLevel: {
      integerValue: 0,
    },
    availableActions: ['copy-id'],
  });
};

describe('formatGraphQLGroup', () => {
  it('correctly formats the group with edit, delete, and leave permissions', () => {
    window.gon = { relative_url_root: '/gitlab' };
    const [mockGroup] = organizationGroups;
    const formattedGroup = formatGraphQLGroup(mockGroup, (group) => ({
      customProperty: group.fullName,
    }));

    itCorrectlyFormatsWithActions(formattedGroup, mockGroup);
  });

  it('correctly formats the group without edit, delete, and leave permissions', () => {
    const nonDeletableGroup = organizationGroups[1];
    const formattedGroup = formatGraphQLGroup(nonDeletableGroup);

    itCorrectlyFormatsWithoutActions(formattedGroup, nonDeletableGroup);
  });
});

describe('formatGraphQLGroups', () => {
  it('correctly formats the groups with edit, delete, and leave permissions', () => {
    window.gon = { relative_url_root: '/gitlab' };
    const [firstMockGroup] = organizationGroups;
    const formattedGroups = formatGraphQLGroups(organizationGroups, (group) => ({
      customProperty: group.fullName,
    }));
    const [firstFormattedGroup] = formattedGroups;

    itCorrectlyFormatsWithActions(firstFormattedGroup, firstMockGroup);
    expect(formattedGroups).toHaveLength(organizationGroups.length);
  });

  it('correctly formats the groups without edit, delete, and leave permissions', () => {
    const nonDeletableGroup = organizationGroups[1];
    const formattedGroups = formatGraphQLGroups(organizationGroups);
    const nonDeletableFormattedGroup = formattedGroups[1];

    itCorrectlyFormatsWithoutActions(nonDeletableFormattedGroup, nonDeletableGroup);
    expect(formattedGroups).toHaveLength(organizationGroups.length);
  });
});

describe('formatGroupForGraphQLResolver', () => {
  it('correctly formats group with all fields', () => {
    const mockGroup = dashboardGroupsResponse[1];
    const formattedGroup = formatGroupForGraphQLResolver(mockGroup);

    expect(formattedGroup).toMatchObject({
      __typename: TYPENAME_GROUP,
      id: expect.stringContaining('gid://gitlab/Group/'),
      name: mockGroup.name,
      fullName: mockGroup.full_name,
      fullPath: mockGroup.full_path,
      editPath: mockGroup.edit_path,
      withdrawAccessRequestPath: mockGroup.withdraw_access_request_path,
      requestAccessPath: mockGroup.request_access_path,
      descriptionHtml: mockGroup.markdown_description,
      visibility: mockGroup.visibility,
      createdAt: mockGroup.created_at,
      updatedAt: mockGroup.updated_at,
      avatarUrl: mockGroup.avatar_url,
      archived: mockGroup.archived,
      isSelfArchived: mockGroup.is_self_archived,
      markedForDeletion: mockGroup.marked_for_deletion,
      isSelfDeletionInProgress: mockGroup.is_self_deletion_in_progress,
      isSelfDeletionScheduled: mockGroup.is_self_deletion_scheduled,
      userPermissions: {
        archiveGroup: mockGroup.can_archive,
        canLeave: mockGroup.can_leave,
        removeGroup: mockGroup.can_remove,
        viewEditPage: mockGroup.can_edit,
      },
      webUrl: mockGroup.web_url,
      groupMembersCount: mockGroup.group_members_count,
      isLinkedToSubscription: mockGroup.is_linked_to_subscription,
      permanentDeletionDate: mockGroup.permanent_deletion_date,
      maxAccessLevel: {
        integerValue: mockGroup.permission_integer,
      },
      parent: {
        id: mockGroup.parent_id,
      },
      descendantGroupsCount: mockGroup.subgroup_count,
      projectsCount: mockGroup.project_count,
      children: expect.any(Array),
      childrenCount: mockGroup.subgroup_count,
      hasChildren: mockGroup.has_subgroups,
    });
  });

  it('correctly formats nested children groups', () => {
    const mockGroupWithChildren = {
      ...dashboardGroupsResponse[1],
      children: [dashboardGroupsResponse[0]],
    };
    const formattedGroup = formatGroupForGraphQLResolver(mockGroupWithChildren);

    expect(formattedGroup.children).toHaveLength(1);
    expect(formattedGroup.children[0]).toMatchObject({
      __typename: TYPENAME_GROUP,
      id: expect.stringContaining('gid://gitlab/Group/'),
      name: mockGroupWithChildren.children[0].name,
    });
  });
});
