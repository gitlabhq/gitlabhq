import { formatProjects, formatGroups } from '~/organizations/shared/utils';
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
    const [firstMockGroup] = organizationGroups.nodes;
    const formattedGroups = formatGroups(organizationGroups.nodes);
    const [firstFormattedGroup] = formattedGroups;

    expect(firstFormattedGroup).toMatchObject({
      id: getIdFromGraphQLId(firstMockGroup.id),
      editPath: `${firstFormattedGroup.webUrl}/-/edit`,
      availableActions: [ACTION_EDIT, ACTION_DELETE],
    });
    expect(formattedGroups.length).toBe(organizationGroups.nodes.length);
  });
});
