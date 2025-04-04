import { GlIcon, GlAvatarsInline } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MergeRequestListItem from '~/repository/components/header_area/merge_request_list_item.vue';
import { getTimeago } from '~/lib/utils/datetime/timeago_utility';

jest.mock('~/lib/utils/datetime/timeago_utility', () => ({
  getTimeago: jest.fn(),
}));

describe('MergeRequestListItem', () => {
  let wrapper;
  const mockTimeago = {
    format: jest.fn().mockReturnValue('3 days ago'),
  };

  const mockAssignees = [
    { id: 'gid://gitlab/User/1', name: 'User One', avatarUrl: '/avatars/user1.png' },
    { id: 'gid://gitlab/User/2', name: 'User Two', avatarUrl: '/avatars/user2.png' },
  ];

  const mockAuthor = {
    id: 'gid://gitlab/User/3',
    name: 'Author User',
    avatarUrl: '/avatars/author.png',
  };

  const createMergeRequestMock = (overrides = {}) => ({
    id: 'gid://gitlab/MergeRequest/1',
    iid: '123',
    title: 'Test MR title',
    createdAt: '2023-01-01T00:00:00Z',
    sourceBranch: 'feature-branch',
    project: {
      fullPath: 'group/project',
    },
    author: mockAuthor,
    assignees: {
      nodes: mockAssignees,
    },
    ...overrides,
  });

  const createComponent = (props) => {
    wrapper = shallowMountExtended(MergeRequestListItem, {
      propsData: {
        mergeRequest: createMergeRequestMock(),
        ...props,
      },
      stubs: {
        GlAvatarsInline,
      },
    });
  };

  const findMergeIcon = () => wrapper.findComponent(GlIcon);
  const findTitle = () => wrapper.findByText('Test MR title');
  const findAvatarsInline = () => wrapper.findComponent(GlAvatarsInline);

  beforeEach(() => {
    getTimeago.mockReturnValue(mockTimeago);
    createComponent();
  });

  describe('rendering', () => {
    it('renders a merge icon', () => {
      expect(findMergeIcon().exists()).toBe(true);
    });

    it('renders the merge request title', () => {
      expect(findTitle().exists()).toBe(true);
    });

    it('renders the formatted creation time', () => {
      expect(mockTimeago.format).toHaveBeenCalledWith('2023-01-01T00:00:00Z');
      expect(wrapper.find('time').text()).toBe('3 days ago');
    });
  });

  describe('assignees', () => {
    it('renders assignees with GlAvatarsInline component', () => {
      const avatarsInline = findAvatarsInline();
      expect(avatarsInline.exists()).toBe(true);
      expect(avatarsInline.props('avatars')).toEqual(mockAssignees);
      expect(avatarsInline.props('maxVisible')).toBe(3);
    });

    it('falls back to author when no assignees are present', () => {
      const mrWithNoAssignees = createMergeRequestMock({ assignees: { nodes: [] } });
      createComponent({ mergeRequest: mrWithNoAssignees });

      const avatarsInline = findAvatarsInline();
      expect(avatarsInline.exists()).toBe(true);
      expect(avatarsInline.props('avatars')).toEqual([mockAuthor]);
    });
  });
});
