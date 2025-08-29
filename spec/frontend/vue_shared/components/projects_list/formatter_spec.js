import projectsGraphQLResponse from 'test_fixtures/graphql/organizations/projects.query.graphql.json';
import {
  formatGraphQLProjects,
  formatGraphQLProject,
} from '~/vue_shared/components/projects_list/formatter';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';

const MOCK_AVAILABLE_ACTIONS = [ACTION_EDIT, ACTION_DELETE];

jest.mock('~/vue_shared/components/projects_list/utils', () => ({
  availableGraphQLProjectActions: jest.fn(() => MOCK_AVAILABLE_ACTIONS),
}));

const {
  data: {
    organization: {
      projects: { nodes: projects },
    },
  },
} = projectsGraphQLResponse;

afterEach(() => {
  window.gon = {};
});

const itCorrectlyFormatsProject = (formattedProject, mockProject) => {
  expect(formattedProject).toMatchObject({
    id: getIdFromGraphQLId(mockProject.id),
    nameWithNamespace: mockProject.nameWithNamespace,
    avatarLabel: mockProject.nameWithNamespace,
    mergeRequestsAccessLevel: mockProject.mergeRequestsAccessLevel.stringValue,
    issuesAccessLevel: mockProject.issuesAccessLevel.stringValue,
    forkingAccessLevel: mockProject.forkingAccessLevel.stringValue,
    accessLevel: {
      integerValue: 50,
    },
    availableActions: ['edit', 'delete'],
    customProperty: mockProject.nameWithNamespace,
    isPersonal: false,
    relativeWebUrl: `/gitlab/${mockProject.fullPath}`,
  });
};

describe('formatGraphQLProject', () => {
  it('correctly formats the projects', () => {
    window.gon = { relative_url_root: '/gitlab' };
    const [mockProject] = projects;
    const formattedProject = formatGraphQLProject(mockProject, (project) => ({
      customProperty: project.nameWithNamespace,
    }));

    itCorrectlyFormatsProject(formattedProject, mockProject);
  });
});

describe('formatGraphQLProjects', () => {
  it('correctly formats the projects', () => {
    window.gon = { relative_url_root: '/gitlab' };
    const [firstMockProject] = projects;
    const formattedProjects = formatGraphQLProjects(projects, (project) => ({
      customProperty: project.nameWithNamespace,
    }));
    const [firstFormattedProject] = formattedProjects;

    itCorrectlyFormatsProject(firstFormattedProject, firstMockProject);

    expect(formattedProjects).toHaveLength(projects.length);
  });
});
