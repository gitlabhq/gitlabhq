import organizationGroupsGraphQlResponse from 'test_fixtures/graphql/organizations/groups.query.graphql.json';
import { formatGraphQLGroups } from '~/vue_shared/components/groups_list/formatter';
import {
  ACTION_EDIT,
  ACTION_LEAVE,
  ACTION_RESTORE,
  ACTION_DELETE_IMMEDIATELY,
} from '~/vue_shared/components/list_actions/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

const {
  data: {
    organization: {
      groups: { nodes: organizationGroups },
    },
  },
} = organizationGroupsGraphQlResponse;

afterEach(() => {
  window.gon = {};
});

describe('formatGraphQLGroups', () => {
  it('correctly formats the groups with edit, delete, and leave permissions', () => {
    window.gon = { relative_url_root: '/gitlab' };
    const [firstMockGroup] = organizationGroups;
    const formattedGroups = formatGraphQLGroups(organizationGroups, (group) => ({
      customProperty: group.fullName,
    }));
    const [firstFormattedGroup] = formattedGroups;

    expect(firstFormattedGroup).toMatchObject({
      id: getIdFromGraphQLId(firstMockGroup.id),
      avatarLabel: firstMockGroup.fullName,
      fullName: firstMockGroup.fullName,
      parent: null,
      accessLevel: {
        integerValue: 50,
      },
      availableActions: [ACTION_EDIT, ACTION_RESTORE, ACTION_LEAVE, ACTION_DELETE_IMMEDIATELY],
      children: [],
      childrenLoading: false,
      hasChildren: false,
      relativeWebUrl: `/gitlab/${firstMockGroup.fullPath}`,
      customProperty: firstMockGroup.fullName,
    });
    expect(formattedGroups).toHaveLength(organizationGroups.length);
  });

  it('correctly formats the groups without edit, delete, and leave permissions', () => {
    const nonDeletableGroup = organizationGroups[1];
    const formattedGroups = formatGraphQLGroups(organizationGroups);
    const nonDeletableFormattedGroup = formattedGroups[1];

    expect(nonDeletableFormattedGroup).toMatchObject({
      id: getIdFromGraphQLId(nonDeletableGroup.id),
      avatarLabel: nonDeletableGroup.fullName,
      fullName: nonDeletableGroup.fullName,
      parent: null,
      accessLevel: {
        integerValue: 0,
      },
      availableActions: [],
    });

    expect(formattedGroups).toHaveLength(organizationGroups.length);
  });
});
