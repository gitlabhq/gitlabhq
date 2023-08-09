import { formatProjects, formatGroups } from '~/organizations/groups_and_projects/utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { organizationProjects, organizationGroups } from './mock_data';

describe('formatProjects', () => {
  it('correctly formats the projects', () => {
    const [firstMockProject] = organizationProjects.nodes;
    const formattedProjects = formatProjects(organizationProjects.nodes);
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
    expect(formattedProjects.length).toBe(organizationProjects.nodes.length);
  });
});

describe('formatGroups', () => {
  it('correctly formats the groups', () => {
    const [firstMockGroup] = organizationGroups.nodes;
    const formattedGroups = formatGroups(organizationGroups.nodes);
    const [firstFormattedGroup] = formattedGroups;

    expect(firstFormattedGroup.id).toBe(getIdFromGraphQLId(firstMockGroup.id));
    expect(formattedGroups.length).toBe(organizationGroups.nodes.length);
  });
});
