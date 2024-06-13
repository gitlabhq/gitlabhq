import { GlLink, GlIcon, GlAvatarsInline, GlAvatarLink, GlAvatar } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { workItemDevelopmentNodes } from 'jest/work_items/mock_data';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { STATUS_OPEN, STATUS_CLOSED, STATUS_MERGED } from '~/issues/constants';
import WorkItemDevelopmentMRItem from '~/work_items/components/work_item_development/work_item_development_mr_item.vue';

describe('WorkItemDevelopmentMRItem', () => {
  let wrapper;

  const openMergeRequest = workItemDevelopmentNodes[0].mergeRequest;
  const closedMergeRequest = {
    ...openMergeRequest,
    state: STATUS_CLOSED,
  };
  const mergedMergeRequest = {
    ...openMergeRequest,
    state: STATUS_MERGED,
  };

  const mergeRequestWithNoAssignees = workItemDevelopmentNodes[1].mergeRequest;

  const createComponent = ({ mergeRequest = openMergeRequest, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(WorkItemDevelopmentMRItem, {
      propsData: {
        mergeRequest,
      },
    });
  };

  const findMRStatusBadge = () => wrapper.findComponent(GlIcon);
  const findMRTitle = () => wrapper.findComponent(GlLink);
  const findAssigneeAvatars = () => wrapper.findComponent(GlAvatarsInline);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findAvatar = () => wrapper.findComponent(GlAvatar);

  describe('MR status badge', () => {
    it.each`
      state            | icon                     | mergeRequest          | iconClass
      ${STATUS_OPEN}   | ${'merge-request'}       | ${openMergeRequest}   | ${'gl-text-green-500'}
      ${STATUS_MERGED} | ${'merge'}               | ${mergedMergeRequest} | ${'gl-text-blue-500'}
      ${STATUS_CLOSED} | ${'merge-request-close'} | ${closedMergeRequest} | ${'gl-text-red-500'}
    `(
      'renders icon "$icon" when the state of the MR is "$state"',
      ({ icon, iconClass, mergeRequest }) => {
        createComponent({ mergeRequest });

        expect(findMRStatusBadge().props('name')).toBe(icon);
        expect(findMRStatusBadge().attributes('class')).toBe(iconClass);
      },
    );
  });

  describe('MR title', () => {
    it('should render the title as a link', () => {
      createComponent();
      expect(findMRTitle().attributes('href')).toBe(openMergeRequest.webUrl);
    });

    it('should have all the data attributes passed to the link so that a popover is rendered on hover', () => {
      createComponent();

      expect(findMRTitle().attributes()).toMatchObject({
        'data-reference-type': 'merge_request',
        'data-project-path': 'flightjs/Flight',
        'data-iid': `${getIdFromGraphQLId(openMergeRequest.iid)}`,
        'data-mr-title': openMergeRequest.title,
      });
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
});
