import projectsGraphQLResponse from 'test_fixtures/graphql/organizations/projects.query.graphql.json';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';

const {
  data: {
    organization: {
      projects: { nodes: projects },
    },
  },
} = projectsGraphQLResponse;

describe('formatGraphQLProjects', () => {
  it('correctly formats the projects', () => {
    const [firstMockProject] = projects;
    const formattedProjects = formatGraphQLProjects(projects);
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

    expect(formattedProjects.length).toBe(projects.length);
  });

  describe('when project does not have delete permissions', () => {
    const nonDeletableFormattedProject = formatGraphQLProjects(projects)[1];

    it('does not include delete action in `availableActions`', () => {
      expect(nonDeletableFormattedProject.availableActions).toEqual([]);
    });
  });

  describe('when project does not have edit permissions', () => {
    const nonEditableFormattedProject = formatGraphQLProjects(projects)[1];

    it('does not include edit action in `availableActions`', () => {
      expect(nonEditableFormattedProject.availableActions).toEqual([]);
    });
  });
});
