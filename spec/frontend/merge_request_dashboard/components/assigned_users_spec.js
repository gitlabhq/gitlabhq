import { mountExtended } from 'helpers/vue_test_utils_helper';
import AssignedUsers from '~/merge_request_dashboard/components/assigned_users.vue';

let wrapper;
let glTooltipDirectiveMock;

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

function createComponent({
  users = createMockUsers(),
  type = 'ASSIGNEES',
  newListsEnabled = false,
} = {}) {
  glTooltipDirectiveMock = jest.fn();

  wrapper = mountExtended(AssignedUsers, {
    directives: {
      GlTooltip: glTooltipDirectiveMock,
    },
    provide: {
      newListsEnabled,
    },
    propsData: {
      type,
      users,
    },
  });
}

describe('Merge request dashboard assigned users component', () => {
  const findAllUsers = () => wrapper.findAllByTestId('assigned-user');
  const findReviewStateIcon = () => wrapper.findByTestId('review-state-icon');
  const findCurrentUserIcon = () => wrapper.findByTestId('current-user');

  beforeEach(() => {
    window.gon = { current_user_id: 1 };
  });

  afterEach(() => {
    window.gon = {};
  });

  it('renders user avatars', () => {
    createComponent();

    expect(findAllUsers()).toHaveLength(2);
    expect(wrapper.html()).toMatchSnapshot();
  });

  describe('current user avatar', () => {
    it('renders icon for current user', () => {
      createComponent();

      expect(findCurrentUserIcon().exists()).toBe(true);
    });

    it('adds this is you text to tooltip', () => {
      createComponent();

      expect(glTooltipDirectiveMock.mock.calls[1][1].value).toBe(
        '<strong>This is you.</strong><br />Assigned to Admin',
      );
    });

    it('renders current user last', () => {
      createComponent();

      expect(findAllUsers().at(1).find('[data-testid="current-user"]').exists()).toBe(true);
    });

    describe('when newListsEnabled is true', () => {
      it('renders icon for current user', () => {
        createComponent({ newListsEnabled: true });

        expect(findCurrentUserIcon().exists()).toBe(false);
      });
    });
  });

  describe('as reviewer list', () => {
    it('renders review state icon', () => {
      createComponent({ type: 'REVIEWER' });

      expect(findReviewStateIcon().exists()).toBe(true);
      expect(findReviewStateIcon().html()).toMatchSnapshot();
    });

    it.each`
      state                  | title
      ${'REQUESTED_CHANGES'} | ${'Admin requested changes'}
      ${'APPROVED'}          | ${'Approved by Admin'}
      ${'REVIEWED'}          | ${'Admin left feedback'}
      ${'UNREVIEWED'}        | ${'Review requested from Admin'}
    `('sets title as $title for review state $state', ({ state, title }) => {
      createComponent({
        type: 'REVIEWER',
        users: [
          {
            id: 'gid://gitlab/user/2',
            webUrl: '/root',
            name: 'Admin',
            avatarUrl: '/root',
            mergeRequestInteraction: {
              reviewState: state,
            },
          },
        ],
      });

      expect(glTooltipDirectiveMock.mock.calls[0][1].value).toBe(title);
    });
  });
});
