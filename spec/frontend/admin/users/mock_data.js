import { range } from 'lodash';
import { OBSTACLE_TYPES } from '~/vue_shared/components/user_deletion_obstacles/constants';
import { SOLO_OWNED_ORGANIZATIONS_REQUESTED_COUNT } from '~/admin/users/constants';

export const users = [
  {
    id: 2177,
    name: 'Nikki',
    createdAt: '2020-11-13T12:26:54.177Z',
    email: 'nikki@example.com',
    username: 'nikki',
    lastActivityOn: '2020-12-09',
    avatarUrl:
      'https://secure.gravatar.com/avatar/054f062d8b1a42b123f17e13a173cda8?s=80\\u0026d=identicon',
    badges: [
      { text: 'Admin', variant: 'success' },
      { text: "It's you!", variant: 'muted' },
    ],
    projectsCount: 0,
    actions: [],
    note: 'Create per issue #999',
  },
];

export const user = users[0];

export const paths = {
  edit: '/admin/users/id/edit',
  approve: '/admin/users/id/approve',
  reject: '/admin/users/id/reject',
  unblock: '/admin/users/id/unblock',
  block: '/admin/users/id/block',
  deactivate: '/admin/users/id/deactivate',
  activate: '/admin/users/id/activate',
  unlock: '/admin/users/id/unlock',
  delete: '/admin/users/id',
  deleteWithContributions: '/admin/users/id?hard_delete=true',
  adminUser: '/admin/users/id',
  ban: '/admin/users/id/ban',
  unban: '/admin/users/id/unban',
};

export const createGroupCountResponse = (groupCounts) => ({
  data: {
    users: {
      nodes: groupCounts.map(({ id, groupCount }) => ({
        id: `gid://gitlab/User/${id}`,
        groupCount,
        __typename: 'UserCore',
      })),
      __typename: 'UserCoreConnection',
    },
  },
});

export const associationsCount = {
  groups_count: 5,
  projects_count: 5,
  issues_count: 5,
  merge_requests_count: 5,
};

export const userDeletionObstacles = [
  { name: 'schedule1', type: OBSTACLE_TYPES.oncallSchedules },
  { name: 'policy1', type: OBSTACLE_TYPES.escalationPolicies },
];

export const userStatus = {
  emoji: 'basketball',
  message: 'test',
  availability: 'busy',
  message_html: 'test',
  clear_status_at: '2023-01-04T10:00:00.000Z',
};

const organization = (index) => ({
  id: `gid://gitlab/Organizations::Organization/${index}`,
  name: `Foo ${index}`,
  webUrl: `http://gdk.test:3000/-/organizations/foo-${index}`,
});

export const oneSoloOwnedOrganization = {
  count: 1,
  nodes: [organization(0)],
};

export const twoSoloOwnedOrganizations = {
  count: 2,
  nodes: range(2).map((index) => organization(index)),
};

export const multipleSoloOwnedOrganizations = {
  count: 3,
  nodes: range(3).map((index) => organization(index)),
};

export const multipleWithOneExtraSoloOwnedOrganizations = {
  count: 11,
  nodes: range(SOLO_OWNED_ORGANIZATIONS_REQUESTED_COUNT).map((index) => organization(index)),
};

export const multipleWithExtrasSoloOwnedOrganizations = {
  count: 12,
  nodes: range(SOLO_OWNED_ORGANIZATIONS_REQUESTED_COUNT).map((index) => organization(index)),
};
