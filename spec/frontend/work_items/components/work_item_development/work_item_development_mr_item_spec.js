import { GlLink, GlAvatarsInline, GlAvatarLink, GlAvatar, GlIcon, GlBadge } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { workItemDevelopmentMRNodes } from 'jest/work_items/mock_data';
import { STATUS_CLOSED } from '~/issues/constants';
import WorkItemDevelopmentMRItem from '~/work_items/components/work_item_development/work_item_development_mr_item.vue';
import toast from '~/vue_shared/plugins/global_toast';

jest.mock('~/vue_shared/plugins/global_toast', () => jest.fn());
jest.mock('~/lib/utils/datetime_utility', () => ({
  localeDateFormat: {
    asDateTimeFull: {
      format: jest.fn().mockReturnValue('February 6, 2025 at 9:43:01 PM GMT'),
    },
  },
  newDate: jest.fn((date) => new Date(date)),
}));

describe('WorkItemDevelopmentMRItem', () => {
  let wrapper;

  const openMergeRequest = workItemDevelopmentMRNodes[0].mergeRequest;

  const closedMergeRequest = {
    ...openMergeRequest,
    state: STATUS_CLOSED,
  };

  const mergeRequestWithNoAssignees = workItemDevelopmentMRNodes[1].mergeRequest;

  const createComponent = ({
    mergeRequest = openMergeRequest,
    mountFn = shallowMount,
    workItemFullPath = 'top-group/subgroup/my-project',
  } = {}) => {
    wrapper = mountFn(WorkItemDevelopmentMRItem, {
      propsData: {
        itemContent: mergeRequest,
        workItemFullPath,
      },
    });
  };

  const findMRTitle = () => wrapper.findComponent(GlLink);
  const findMRReference = () => wrapper.find('[data-testid="mr-reference"]');
  const findMRIcon = () => wrapper.findComponent(GlIcon);
  const findAssigneeAvatars = () => wrapper.findComponent(GlAvatarsInline);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findCopyReferenceDropdownItem = () => wrapper.find('[data-testid="mr-copy-reference"]');
  const findBadge = () => wrapper.findComponent(GlBadge);

  describe('MR title', () => {
    it('should render the title as a link', () => {
      createComponent();
      expect(findMRTitle().attributes('href')).toBe(openMergeRequest.webUrl);
    });
  });

  describe('MR assignees avatars', () => {
    it('should not be visible when there are no assignees of the MR', () => {
      createComponent({ mergeRequest: mergeRequestWithNoAssignees });

      expect(findAssigneeAvatars().exists()).toBe(false);
    });

    it('should be visible when there are assignees of the MR', () => {
      createComponent();

      expect(findAssigneeAvatars().exists()).toBe(true);
    });

    it('should have the link to the avatar to the assignees', () => {
      createComponent({ mountFn: mount });

      expect(findAvatarLink().exists()).toBe(true);
      expect(findAvatar().exists()).toBe(true);
    });
  });

  it('has subtle class for closed merge requests', () => {
    createComponent({ mergeRequest: closedMergeRequest });

    expect(findMRTitle().classes()).toContain('gl-text-subtle');
    expect(findMRIcon().attributes('class')).toContain('gl-fill-icon-subtle');
  });

  it('has icon tooltip', () => {
    createComponent();

    expect(findMRIcon().attributes('title')).toBe('Merge request');
  });

  describe('Badge', () => {
    it('shows a badge when closed', () => {
      createComponent({ mergeRequest: closedMergeRequest });

      expect(findBadge().exists()).toBe(true);
      expect(findBadge().props('variant')).toBe('danger');
      expect(findBadge().attributes('title')).toBe('February 6, 2025 at 9:43:01 PM GMT');
      expect(findBadge().text()).toBe('Closed');
    });
    it('shows a badge when merged', () => {
      createComponent({ mergeRequest: mergeRequestWithNoAssignees });

      expect(findBadge().exists()).toBe(true);
      expect(findBadge().props('variant')).toBe('info');
      expect(findBadge().attributes('title')).toBe('February 6, 2025 at 9:43:01 PM GMT');
      expect(findBadge().text()).toBe('Merged');
    });
  });

  describe('MR references', () => {
    const expectedFullPath = `${openMergeRequest.project.fullPath}${openMergeRequest.reference}`;

    it('should show only the reference when in same namespace', () => {
      createComponent();
      expect(findMRReference().text()).toBe(openMergeRequest.reference);
      expect(findMRReference().attributes('title')).toBe(expectedFullPath);
    });
    it('should show the project when not in same namespace', () => {
      createComponent({ workItemFullPath: 'gitlab-org/gitlab' });
      expect(findMRReference().text()).toBe(
        `${openMergeRequest.project.path}${openMergeRequest.reference}`,
      );
      expect(findMRReference().attributes('title')).toBe(expectedFullPath);
    });
    it('should copy the full path using copy reference', () => {
      createComponent({ mountFn: mount });

      const copyRefItem = findCopyReferenceDropdownItem();
      expect(copyRefItem.exists()).toBe(true);
      expect(copyRefItem.attributes('data-clipboard-text')).toBe(expectedFullPath);

      const mockCopyToClipboard = jest.spyOn(wrapper.vm, 'copyToClipboard');
      copyRefItem.vm.$emit('action');
      expect(mockCopyToClipboard).toHaveBeenCalledWith(expectedFullPath, 'Copied reference.');
      expect(toast).toHaveBeenCalledWith('Copied reference.');
    });
  });
});
