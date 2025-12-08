import { mountExtended } from 'helpers/vue_test_utils_helper';
import AssignedUsers from '~/merge_request_dashboard/components/assigned_users.vue';

let wrapper;

const createMockUsers = () => [
  {
    id: 'gid://gitlab/user/1',
    webUrl: '/root',
    name: 'Admin',
    avatarUrl: '/root',
  },
  {
    id: 'gid://gitlab/user/2',
    webUrl: '/root',
    name: 'Admin',
    avatarUrl: '/root',
    mergeRequestInteraction: {
      reviewState: 'REQUESTED_CHANGES',
    },
  },
];

function createComponent({ users = createMockUsers(), type = 'ASSIGNEES' } = {}) {
  wrapper = mountExtended(AssignedUsers, {
    propsData: {
      type,
      users,
    },
  });
}

describe('Merge request dashboard assigned users component', () => {
  const findAllUsers = () => wrapper.findAllByTestId('assigned-user');
  const findReviewStateIcon = () => wrapper.findByTestId('review-state-icon');
  const findShowAllUsersButton = () => wrapper.findByTestId('show-all-users');

  it('renders user avatars', () => {
    createComponent();

    expect(findAllUsers()).toHaveLength(2);
  });

  it('shows all users when at the limit', () => {
    createComponent({
      users: [
        ...createMockUsers(),
        ...createMockUsers().map((user) => ({ ...user, id: `gid://gitlab/user/${user.id + 2}` })),
      ],
    });

    expect(findAllUsers()).toHaveLength(4);
    expect(findShowAllUsersButton().exists()).toBe(false);
  });

  it('shows extra users in popover when over the limit', () => {
    createComponent({
      users: [
        ...createMockUsers(),
        ...createMockUsers().map((user) => ({ ...user, id: `gid://gitlab/user/${user.id + 2}` })),
        ...createMockUsers().map((user) => ({ ...user, id: `gid://gitlab/user/${user.id + 4}` })),
      ],
    });

    expect(findAllUsers()).toHaveLength(3);
    expect(findShowAllUsersButton().exists()).toBe(true);
    expect(findShowAllUsersButton().attributes('title')).toEqual('Show all assignees');
  });

  describe('as reviewer list', () => {
    it('renders review state icon', () => {
      createComponent({ type: 'REVIEWER' });

      expect(findReviewStateIcon().exists()).toBe(true);
      expect(findReviewStateIcon().html()).toMatchSnapshot();
    });
  });
});
