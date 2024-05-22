import organizationGroupsGraphQlResponse from 'test_fixtures/graphql/organizations/groups.query.graphql.json';
import organizationProjectsGraphQlResponse from 'test_fixtures/graphql/organizations/projects.query.graphql.json';
import {
  formatProjects,
  formatGroups,
  onPageChange,
  deleteParams,
  renderDeleteSuccessToast,
  timestampType,
} from '~/organizations/shared/utils';
import { SORT_CREATED_AT, SORT_UPDATED_AT, SORT_NAME } from '~/organizations/shared/constants';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import toast from '~/vue_shared/plugins/global_toast';
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

describe('formatProjects', () => {
  it('correctly formats the projects', () => {
    const [firstMockProject] = organizationProjects;
    const formattedProjects = formatProjects(organizationProjects);
    const [firstFormattedProject] = formattedProjects;

    expect(firstFormattedProject).toMatchObject({
      id: getIdFromGraphQLId(firstMockProject.id),
      name: firstMockProject.nameWithNamespace,
      mergeRequestsAccessLevel: firstMockProject.mergeRequestsAccessLevel.stringValue,
      issuesAccessLevel: firstMockProject.issuesAccessLevel.stringValue,
      forkingAccessLevel: firstMockProject.forkingAccessLevel.stringValue,
      accessLevel: {
        integerValue: 50,
      },
      availableActions: [ACTION_EDIT, ACTION_DELETE],
      actionLoadingStates: {
        [ACTION_DELETE]: false,
      },
    });

    expect(formattedProjects.length).toBe(organizationProjects.length);
  });

  describe('when project does not have delete permissions', () => {
    const nonDeletableFormattedProject = formatProjects(organizationProjects)[1];

    it('does not include delete action in `availableActions`', () => {
      expect(nonDeletableFormattedProject.availableActions).toEqual([]);
    });
  });

  describe('when project does not have edit permissions', () => {
    const nonEditableFormattedProject = formatProjects(organizationProjects)[1];

    it('does not include edit action in `availableActions`', () => {
      expect(nonEditableFormattedProject.availableActions).toEqual([]);
    });
  });
});

describe('formatGroups', () => {
  it('correctly formats the groups with edit and delete permissions', () => {
    const [firstMockGroup] = organizationGroups;
    const formattedGroups = formatGroups(organizationGroups);
    const [firstFormattedGroup] = formattedGroups;

    expect(firstFormattedGroup).toMatchObject({
      id: getIdFromGraphQLId(firstMockGroup.id),
      name: firstMockGroup.fullName,
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
      name: nonDeletableGroup.fullName,
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

describe('onPageChange', () => {
  const mockRouteQuery = { start_cursor: 'mockStartCursor', end_cursor: 'mockEndCursor' };

  describe('when `startCursor` is defined', () => {
    it('sets start cursor query param', () => {
      expect(
        onPageChange({
          startCursor: 'newMockStartCursor',
          routeQuery: mockRouteQuery,
        }),
      ).toEqual({ start_cursor: 'newMockStartCursor' });
    });
  });

  describe('when `endCursor` is defined', () => {
    it('sets end cursor query param', () => {
      expect(
        onPageChange({
          endCursor: 'newMockEndCursor',
          routeQuery: mockRouteQuery,
        }),
      ).toEqual({ end_cursor: 'newMockEndCursor' });
    });
  });
});

describe('renderDeleteSuccessToast', () => {
  const [MOCK_PROJECT] = formatProjects(organizationProjects);
  const MOCK_TYPE = 'Project';

  it('calls toast correctly', () => {
    renderDeleteSuccessToast(MOCK_PROJECT, MOCK_TYPE);

    expect(toast).toHaveBeenCalledWith(`${MOCK_TYPE} '${MOCK_PROJECT.name}' is being deleted.`);
  });
});

describe('deleteParams', () => {
  it('returns {} always', () => {
    expect(deleteParams()).toStrictEqual({});
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
