export const MOCK_ORGANIZATION_GID = 'gid://gitlab/Organizations::Organization/1';

export const MOCK_USERS = [
  {
    badges: [],
    id: 'gid://gitlab/Organizations::OrganizationUser/3',
    user: { id: 'gid://gitlab/User/3' },
  },
  {
    badges: [],
    id: 'gid://gitlab/Organizations::OrganizationUser/2',
    user: { id: 'gid://gitlab/User/2' },
  },
  {
    badges: ['Admin', "It's you!"],
    id: 'gid://gitlab/Organizations::OrganizationUser/1',
    user: { id: 'gid://gitlab/User/1' },
  },
];
