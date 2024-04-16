import {
  formatProjects,
  formatGroups,
  onPageChange,
  deleteProjectParams,
  renderProjectDeleteSuccessToast,
} from '~/organizations/shared/utils';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import toast from '~/vue_shared/plugins/global_toast';
import { organizationProjects, organizationGroups } from '~/organizations/mock_data';

jest.mock('~/vue_shared/plugins/global_toast');

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
        integerValue: 30,
      },
      availableActions: [ACTION_EDIT, ACTION_DELETE],
      actionLoadingStates: {
        [ACTION_DELETE]: false,
      },
    });

    expect(formattedProjects.length).toBe(organizationProjects.length);
  });

  describe('when project does not have delete permissions', () => {
    const [firstProject] = organizationProjects;
    const nonDeletableProject = {
      ...firstProject,
      userPermissions: { ...firstProject.userPermissions, removeProject: false },
    };
    const [nonDeletableFormattedProject] = formatProjects([nonDeletableProject]);

    it('does not include delete action in `availableActions`', () => {
      expect(nonDeletableFormattedProject.availableActions).toEqual([ACTION_EDIT]);
    });
  });

  describe('when project does not have edit permissions', () => {
    const [firstProject] = organizationProjects;
    const nonEditableProject = {
      ...firstProject,
      userPermissions: { ...firstProject.userPermissions, viewEditPage: false },
    };
    const [nonEditableFormattedProject] = formatProjects([nonEditableProject]);

    it('does not include edit action in `availableActions`', () => {
      expect(nonEditableFormattedProject.availableActions).toEqual([ACTION_DELETE]);
    });
  });
});

describe('formatGroups', () => {
  it('correctly formats the groups with delete permissions', () => {
    const [firstMockGroup] = organizationGroups;
    const formattedGroups = formatGroups(organizationGroups);
    const [firstFormattedGroup] = formattedGroups;

    expect(firstFormattedGroup).toMatchObject({
      id: getIdFromGraphQLId(firstMockGroup.id),
      parent: null,
      editPath: `${firstFormattedGroup.webUrl}/-/edit`,
      accessLevel: {
        integerValue: 30,
      },
      availableActions: [ACTION_EDIT, ACTION_DELETE],
      actionLoadingStates: {
        [ACTION_DELETE]: false,
      },
    });
    expect(formattedGroups.length).toBe(organizationGroups.length);
  });

  it('correctly formats the groups without delete permissions', () => {
    const nonDeletableGroup = organizationGroups[organizationGroups.length - 1];
    const formattedGroups = formatGroups(organizationGroups);
    const nonDeletableFormattedGroup = formattedGroups[formattedGroups.length - 1];

    expect(nonDeletableFormattedGroup).toMatchObject({
      id: getIdFromGraphQLId(nonDeletableGroup.id),
      parent: null,
      editPath: `${nonDeletableFormattedGroup.webUrl}/-/edit`,
      accessLevel: {
        integerValue: 30,
      },
      availableActions: [ACTION_EDIT],
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

describe('renderProjectDeleteSuccessToast', () => {
  const [MOCK_PROJECT] = formatProjects(organizationProjects);

  it('calls toast correctly', () => {
    renderProjectDeleteSuccessToast(MOCK_PROJECT);

    expect(toast).toHaveBeenCalledWith(`Project '${MOCK_PROJECT.name}' is being deleted.`);
  });
});

describe('deleteProjectParams', () => {
  it('returns {} always', () => {
    expect(deleteProjectParams()).toStrictEqual({});
  });
});
