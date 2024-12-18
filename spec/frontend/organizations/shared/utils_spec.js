import organizationGroupsGraphQlResponse from 'test_fixtures/graphql/organizations/groups.query.graphql.json';
import organizationProjectsGraphQlResponse from 'test_fixtures/graphql/organizations/projects.query.graphql.json';
import { formatGroups, formatProjects, timestampType } from '~/organizations/shared/utils';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';
import { SORT_CREATED_AT, SORT_UPDATED_AT, SORT_NAME } from '~/organizations/shared/constants';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';

jest.mock('~/vue_shared/plugins/global_toast');

const {
  data: {
    organization: {
      groups: { nodes: organizationGroups },
    },
  },
} = organizationGroupsGraphQlResponse;

const {
  data: {
    organization: {
      projects: { nodes: organizationProjects },
    },
  },
} = organizationProjectsGraphQlResponse;

describe('formatGroups', () => {
  it('correctly formats the groups with edit and delete permissions', () => {
    const [firstMockGroup] = organizationGroups;
    const formattedGroups = formatGroups(organizationGroups);
    const [firstFormattedGroup] = formattedGroups;

    expect(firstFormattedGroup).toMatchObject({
      id: getIdFromGraphQLId(firstMockGroup.id),
      avatarLabel: firstMockGroup.fullName,
      fullName: firstMockGroup.fullName,
      parent: null,
      editPath: firstMockGroup.organizationEditPath,
      accessLevel: {
        integerValue: 50,
      },
      availableActions: [ACTION_EDIT, ACTION_DELETE],
      actionLoadingStates: {
        [ACTION_DELETE]: false,
      },
    });
    expect(formattedGroups.length).toBe(organizationGroups.length);
  });

  it('correctly formats the groups without edit or delete permissions', () => {
    const nonDeletableGroup = organizationGroups[1];
    const formattedGroups = formatGroups(organizationGroups);
    const nonDeletableFormattedGroup = formattedGroups[1];

    expect(nonDeletableFormattedGroup).toMatchObject({
      id: getIdFromGraphQLId(nonDeletableGroup.id),
      avatarLabel: nonDeletableGroup.fullName,
      fullName: nonDeletableGroup.fullName,
      parent: null,
      editPath: nonDeletableGroup.organizationEditPath,
      accessLevel: {
        integerValue: 0,
      },
      availableActions: [],
      actionLoadingStates: {
        [ACTION_DELETE]: false,
      },
    });

    expect(formattedGroups.length).toBe(organizationGroups.length);
  });
});

describe('formatProjects', () => {
  it('returns result from formatGraphQLProjects and adds editPath', () => {
    expect(formatProjects(organizationProjects)).toEqual(
      formatGraphQLProjects(organizationProjects).map((project) => ({
        ...project,
        editPath: project.organizationEditPath,
      })),
    );
  });
});

describe('timestampType', () => {
  describe.each`
    sortName           | expectedTimestampType
    ${SORT_CREATED_AT} | ${TIMESTAMP_TYPE_CREATED_AT}
    ${SORT_UPDATED_AT} | ${TIMESTAMP_TYPE_UPDATED_AT}
    ${SORT_NAME}       | ${TIMESTAMP_TYPE_CREATED_AT}
  `('when sort name is $sortName', ({ sortName, expectedTimestampType }) => {
    it(`returns ${expectedTimestampType}`, () => {
      expect(timestampType(sortName)).toBe(expectedTimestampType);
    });
  });
});
