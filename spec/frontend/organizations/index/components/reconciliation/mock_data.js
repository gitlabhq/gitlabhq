import organizationsForReconciliationResponse from 'test_fixtures/graphql/organizations/organizations_for_reconciliation.query.graphql.json';

export const {
  data: {
    organizations: { nodes: mockOrganizations },
  },
} = organizationsForReconciliationResponse;

export const organizationWithGroupsIndex = mockOrganizations.findIndex(
  (organization) => organization.groups.nodes.length,
);
export const organizationWithGroups = mockOrganizations[organizationWithGroupsIndex];

export const organizationWithoutGroupsIndex = mockOrganizations.findIndex(
  (organization) => !organization.groups.nodes.length,
);
export const organizationWithoutGroups = mockOrganizations[organizationWithoutGroupsIndex];

export const organizationsWithoutGroups = mockOrganizations.filter(
  (organization) => !organization.groups.nodes.length,
);

export const [mockGroup] = organizationWithGroups.groups.nodes;
