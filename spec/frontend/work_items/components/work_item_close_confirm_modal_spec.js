import { GlModal, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemCloseConfirmModal from '~/work_items/components/work_item_close_confirm_modal.vue';
import { mockBlockedByLinkedItem } from 'ee_else_ce_jest/work_items/mock_data';

const blockerItems = mockBlockedByLinkedItem.linkedItems.nodes;

const defaultProps = {
  workItemType: 'Task',
  isBlockedByOpenItems: false,
  visible: true,
};

describe('WorkItemCloseConfirmModal', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(WorkItemCloseConfirmModal, {
      propsData: {
        ...defaultProps,
        ...propsData,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findLinks = () => wrapper.findAllComponents(GlLink);

  describe('when work item has open child items', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the modal with correct title', () => {
      expect(findModal().props('title')).toBe('Are you sure you want to close this Task?');
    });

    it('renders the body text about open child items', () => {
      expect(wrapper.text()).toContain(
        'This Task has open child items. If you close this Task, they will remain open.',
      );
    });

    it('does not render blocker links', () => {
      expect(findLinks()).toHaveLength(0);
    });

    it('renders the primary action button text', () => {
      expect(findModal().props('actionPrimary')).toEqual({
        text: 'Yes, close Task',
      });
    });

    it('renders the cancel action button text', () => {
      expect(findModal().props('actionCancel')).toEqual({
        text: 'Cancel',
      });
    });
  });

  describe('when work item is blocked by open items', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          isBlockedByOpenItems: true,
          blockerItems,
        },
      });
    });

    it('renders the modal with blocked title', () => {
      expect(findModal().props('title')).toBe('Are you sure you want to close this blocked Task?');
    });

    it('renders the body text about blocking items', () => {
      expect(wrapper.text()).toContain('This Task is currently blocked by the following items:');
    });

    it('renders blocker links', () => {
      expect(findLinks()).toHaveLength(2);
    });

    it('renders links with correct href and text', () => {
      const links = findLinks();

      expect(links.at(0).attributes('href')).toBe('/gitlab-org/gitlab-test/-/work_items/83');
      expect(links.at(0).text()).toBe('#83');

      expect(links.at(1).attributes('href')).toBe('/gitlab-org/gitlab-test/-/work_items/84');
      expect(links.at(1).text()).toBe('#84');
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits hide when modal is hidden', () => {
      findModal().vm.$emit('hide');

      expect(wrapper.emitted('hide')).toHaveLength(1);
    });

    it('emits proceed when primary action is clicked', () => {
      findModal().vm.$emit('primary');

      expect(wrapper.emitted('proceed')).toHaveLength(1);
    });
  });
});
