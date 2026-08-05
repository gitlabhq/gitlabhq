import organizationsForReconciliationResponse from 'test_fixtures/graphql/organizations/organizations_for_reconciliation.query.graphql.json';
import { mockDefaultOrganization } from 'jest/organizations/shared/mock_data';

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

export const defaultOrgWithGroups = {
  ...mockDefaultOrganization,
  __typename: 'Organization',
  groups: { nodes: [mockGroup], __typename: 'GroupConnection' },
};

export const defaultOrgWithoutGroups = {
  ...mockDefaultOrganization,
  __typename: 'Organization',
  groups: { nodes: [], __typename: 'GroupConnection' },
};

export const organizationsWithDefault = [defaultOrgWithGroups, ...mockOrganizations];
