import projectsGraphQLResponse from 'test_fixtures/graphql/organizations/projects.query.graphql.json';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';

const MOCK_AVAILABLE_ACTIONS = [ACTION_EDIT, ACTION_DELETE];

jest.mock('ee_else_ce/vue_shared/components/projects_list/utils', () => ({
  availableGraphQLProjectActions: jest.fn(() => MOCK_AVAILABLE_ACTIONS),
}));

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
    const formattedProjects = formatGraphQLProjects(projects, (project) => ({
      customProperty: project.nameWithNamespace,
    }));
    const [firstFormattedProject] = formattedProjects;

    expect(firstFormattedProject).toMatchObject({
      id: getIdFromGraphQLId(firstMockProject.id),
      name: firstMockProject.nameWithNamespace,
      nameWithNamespace: firstMockProject.nameWithNamespace,
      avatarLabel: firstMockProject.nameWithNamespace,
      mergeRequestsAccessLevel: firstMockProject.mergeRequestsAccessLevel.stringValue,
      issuesAccessLevel: firstMockProject.issuesAccessLevel.stringValue,
      forkingAccessLevel: firstMockProject.forkingAccessLevel.stringValue,
      accessLevel: {
        integerValue: 50,
      },
      availableActions: ['edit', 'delete'],
      customProperty: firstMockProject.nameWithNamespace,
    });

    expect(formattedProjects.length).toBe(projects.length);
  });
});
