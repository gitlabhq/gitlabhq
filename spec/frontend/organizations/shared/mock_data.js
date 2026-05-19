import { DEFAULT_ORGANIZATION_ID } from '~/organizations/shared/constants';

export const MOCK_NEW_ORG_URL = 'gitlab.com/organizations/new';

export const mockDefaultOrganization = {
  id: `gid://gitlab/Organizations::Organization/${DEFAULT_ORGANIZATION_ID}`,
  name: 'Default',
  avatarUrl: null,
  groups: { nodes: [] },
};
