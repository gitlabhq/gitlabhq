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

  it('renders user avatars', () => {
    createComponent();

    expect(findAllUsers()).toHaveLength(2);
  });

  describe('as reviewer list', () => {
    it('renders review state icon', () => {
      createComponent({ type: 'REVIEWER' });

      expect(findReviewStateIcon().exists()).toBe(true);
      expect(findReviewStateIcon().html()).toMatchSnapshot();
    });
  });
});
