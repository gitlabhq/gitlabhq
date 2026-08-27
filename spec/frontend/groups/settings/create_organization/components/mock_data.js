import groupsResponse from 'test_fixtures/graphql/groups/settings/create_organization/groups.query.graphql.json';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ORGANIZATION } from '~/graphql_shared/constants';
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
  avatarUrl: null,
  groups: { nodes: [mockGroup] },
};

export const mockOrganizations = [mockNewOrganization, mockDefaultOrganization];

export const organizationsWithoutGroups = mockOrganizations.filter(
  (organization) => !organization.groups.nodes.length,
);

export const groupsQueryResponseWithoutDefaultOrgGroups = {
  data: {
    ...groupsResponse.data,
    defaultOrganization: {
      ...mockDefaultOrganization,
      groups: { ...mockDefaultOrganization.groups, nodes: [] },
    },
  },
};

// `groupOrganization` prop as rendered by
// `Organizations::OrganizationHelper#group_settings_create_organization_app_data` for a group that
// still belongs to the default organization.
export const mockDefaultGroupOrganization = {
  id: mockDefaultOrganization.id,
  name: mockDefaultOrganization.name,
  path: mockDefaultOrganization.path,
  visibility: mockDefaultOrganization.visibility,
  avatarUrl: mockDefaultOrganization.avatarUrl,
};

// Same prop for a group that has already been backfilled into its own unconfirmed organization.
export const mockBackfilledGroupOrganization = {
  id: convertToGraphQLId(TYPE_ORGANIZATION, 2),
  name: 'Backfilled organization',
  path: 'backfilled-organization',
  visibility: 'private',
  avatarUrl: null,
};

export const mockBackfilledOrganization = {
  ...mockBackfilledGroupOrganization,
  groups: { nodes: [mockGroup] },
};
