import { GlBadge, GlIcon } from '@gitlab/ui';
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
    { id: 'gid://gitlab/User/1', name: 'User One' },
    { id: 'gid://gitlab/User/2', name: 'User Two' },
  ];

  const createMergeRequestMock = (overrides = {}) => ({
    id: 'gid://gitlab/MergeRequest/1',
    iid: '123',
    title: 'Test MR title',
    createdAt: '2023-01-01T00:00:00Z',
    sourceBranch: 'feature-branch',
    project: {
      fullPath: 'group/project',
    },
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
    });
  };

  const findProjectInfo = () => wrapper.findByTestId('project-info');
  const findAssigneeInfo = () => wrapper.findAllByTestId('assignee-info');
  const findSourceBranchInfo = () => wrapper.findByTestId('source-branch-info');

  beforeEach(() => {
    getTimeago.mockReturnValue(mockTimeago);
    createComponent();
  });

  describe('rendering', () => {
    it('renders the open badge with correct text', () => {
      const badge = wrapper.findComponent(GlBadge);
      expect(badge.exists()).toBe(true);
      expect(badge.text()).toContain('Open');
      expect(badge.findComponent(GlIcon).props('name')).toBe('merge-request');
    });

    it('renders the formatted creation time', () => {
      expect(mockTimeago.format).toHaveBeenCalledWith('2023-01-01T00:00:00Z');
      expect(wrapper.find('time').text()).toBe('3 days ago');
    });

    it('renders the merge request title', () => {
      expect(wrapper.findByText('Test MR title').exists()).toBe(true);
    });

    it('renders the project path and MR ID', () => {
      const projectInfo = findProjectInfo();
      expect(projectInfo.findComponent(GlIcon).props('name')).toBe('project');
      expect(projectInfo.text()).toContain('group/project !123');
    });

    it('renders the source branch', () => {
      const branchInfo = findSourceBranchInfo();
      expect(branchInfo.findComponent(GlIcon).props('name')).toBe('branch');
      expect(branchInfo.text()).toContain('feature-branch');
    });
  });

  describe('assignees', () => {
    it('renders all assignees', () => {
      const assigneeInfos = findAssigneeInfo();
      expect(assigneeInfos.length).toBe(2);

      mockAssignees.forEach((mockUser, index) => {
        const assigneeText = assigneeInfos.at(index).text().trim();
        expect(assigneeText).toContain(mockUser.name);
      });
    });

    it('handles merge requests with no assignees', () => {
      const mrWithNoAssignees = createMergeRequestMock({
        assignees: { nodes: [] },
      });

      createComponent({ mergeRequest: mrWithNoAssignees });

      expect(findAssigneeInfo().length).toBe(0);
    });
  });
});
