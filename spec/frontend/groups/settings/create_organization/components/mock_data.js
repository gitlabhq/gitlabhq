import groupsResponse from 'test_fixtures/graphql/groups/settings/create_organization/groups.query.graphql.json';
import { NEW_ORGANIZATION_GID } from '~/groups/settings/create_organization/constants';

export const groupsQueryResponse = groupsResponse;

export const {
  data: { group: mockGroup, defaultOrganization: mockDefaultOrganization },
} = groupsResponse;

// The organization the user is about to create. It does not exist yet, so `modal.vue` synthesizes
// it client side from the group the reconciliation was started from.
export const mockNewOrganization = {
  id: NEW_ORGANIZATION_GID,
  name: mockGroup.fullName,
  path: mockGroup.path,
  visibility: mockGroup.visibility,
  avatarUrl: mockGroup.avatarUrl,
  groups: { nodes: [mockGroup] },
};

export const mockOrganizations = [mockNewOrganization, mockDefaultOrganization];

export const organizationsWithoutGroups = mockOrganizations.filter(
  (organization) => !organization.groups.nodes.length,
);
