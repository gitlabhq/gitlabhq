import { formatProjects, formatGroups, onPageChange } from '~/organizations/shared/utils';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { organizationProjects, organizationGroups } from '~/organizations/mock_data';

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
      availableActions: [ACTION_EDIT, ACTION_DELETE],
    });
    expect(formattedProjects.length).toBe(organizationProjects.length);
  });
});

describe('formatGroups', () => {
  it('correctly formats the groups', () => {
    const [firstMockGroup] = organizationGroups;
    const formattedGroups = formatGroups(organizationGroups);
    const [firstFormattedGroup] = formattedGroups;

    expect(firstFormattedGroup).toMatchObject({
      id: getIdFromGraphQLId(firstMockGroup.id),
      parent: null,
      editPath: `${firstFormattedGroup.webUrl}/-/edit`,
      availableActions: [ACTION_EDIT, ACTION_DELETE],
    });
    expect(formattedGroups.length).toBe(organizationGroups.length);
  });
});

describe('onPageChange', () => {
  const mockRouteQuery = { start_cursor: 'mockStartCursor', end_cursor: 'mockEndCursor' };

  describe('when `startCursor` is defined and `hasPreviousPage` is `true`', () => {
    it('sets start cursor query param', () => {
      expect(
        onPageChange({
          startCursor: 'newMockStartCursor',
          hasPreviousPage: true,
          routeQuery: mockRouteQuery,
        }),
      ).toEqual({ start_cursor: 'newMockStartCursor' });
    });
  });

  describe('when `startCursor` is defined and `hasPreviousPage` is `false`', () => {
    it('does not set any query params', () => {
      expect(
        onPageChange({
          startCursor: 'newMockStartCursor',
          hasPreviousPage: false,
          routeQuery: mockRouteQuery,
        }),
      ).toEqual({});
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
