import { GlLink, GlAvatarsInline, GlAvatarLink, GlAvatar, GlIcon } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { workItemDevelopmentMRNodes } from 'jest/work_items/mock_data';
import { STATUS_CLOSED } from '~/issues/constants';
import WorkItemDevelopmentMRItem from '~/work_items/components/work_item_development/work_item_development_mr_item.vue';

describe('WorkItemDevelopmentMRItem', () => {
  let wrapper;

  const openMergeRequest = workItemDevelopmentMRNodes[0].mergeRequest;

  const closedMergeRequest = {
    ...openMergeRequest,
    state: STATUS_CLOSED,
  };

  const mergeRequestWithNoAssignees = workItemDevelopmentMRNodes[1].mergeRequest;

  const createComponent = ({ mergeRequest = openMergeRequest, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(WorkItemDevelopmentMRItem, {
      propsData: {
        itemContent: mergeRequest,
      },
    });
  };

  const findMRTitle = () => wrapper.findComponent(GlLink);
  const findMRIcon = () => wrapper.findComponent(GlIcon);
  const findAssigneeAvatars = () => wrapper.findComponent(GlAvatarsInline);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findAvatar = () => wrapper.findComponent(GlAvatar);

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
});
