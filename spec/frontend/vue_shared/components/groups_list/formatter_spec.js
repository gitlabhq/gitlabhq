import organizationGroupsGraphQlResponse from 'test_fixtures/graphql/organizations/groups.query.graphql.json';
import {
  formatGraphQLGroup,
  formatGraphQLGroups,
} from '~/vue_shared/components/groups_list/formatter';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

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
    availableActions: ['edit', 'restore', 'leave', 'delete-immediately'],
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
    availableActions: [],
  });
};

describe('formatGraphQLGroup', () => {
  it('correctly formats the group with edit, delete, and leave permissions', () => {
    window.gon = { relative_url_root: '/gitlab', allow_immediate_namespaces_deletion: true };
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
    window.gon = { relative_url_root: '/gitlab', allow_immediate_namespaces_deletion: true };
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
