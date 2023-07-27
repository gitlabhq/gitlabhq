import { formatProjects } from '~/organizations/groups_and_projects/utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { organizationProjects } from './mock_data';

describe('formatProjects', () => {
  it('correctly formats the projects', () => {
    const [firstMockProject] = organizationProjects.projects.nodes;
    const formattedProjects = formatProjects(organizationProjects.projects.nodes);
    const [firstFormattedProject] = formattedProjects;

    expect(firstFormattedProject).toMatchObject({
      id: getIdFromGraphQLId(firstMockProject.id),
      name: firstMockProject.nameWithNamespace,
      permissions: {
        projectAccess: {
          accessLevel: firstMockProject.accessLevel.integerValue,
        },
      },
    });
    expect(formattedProjects.length).toBe(organizationProjects.projects.nodes.length);
  });
});
