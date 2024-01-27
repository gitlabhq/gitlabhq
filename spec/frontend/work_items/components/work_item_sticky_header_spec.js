import { GlIntersectionObserver } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { STATE_OPEN } from '~/work_items/constants';
import { workItemResponseFactory } from 'jest/work_items/mock_data';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import WorkItemStickyHeader from '~/work_items/components/work_item_sticky_header.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import WorkItemActions from '~/work_items/components/work_item_actions.vue';
import WorkItemTodos from '~/work_items/components/work_item_todos.vue';

describe('WorkItemStickyHeader', () => {
  let wrapper;

  const createComponent = ({ confidential = false, discussionLocked = false } = {}) => {
    wrapper = shallowMountExtended(WorkItemStickyHeader, {
      propsData: {
        workItem: workItemResponseFactory({ canUpdate: true, confidential, discussionLocked }).data
          .workItem,
        fullPath: '/test',
        isStickyHeaderShowing: true,
        workItemNotificationsSubscribed: true,
        updateInProgress: false,
        parentWorkItemConfidentiality: false,
        showWorkItemCurrentUserTodos: true,
        isModal: false,
        currentUserTodos: [],
        workItemState: STATE_OPEN,
      },
    });
  };

  const findStickyHeader = () => wrapper.findByTestId('work-item-sticky-header');
  const findConfidentialityBadge = () => wrapper.findComponent(ConfidentialityBadge);
  const findLockedBadge = () => wrapper.findComponent(LockedBadge);
  const findWorkItemActions = () => wrapper.findComponent(WorkItemActions);
  const findWorkItemTodos = () => wrapper.findComponent(WorkItemTodos);
  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const triggerPageScroll = () => findIntersectionObserver().vm.$emit('disappear');

  it('has the sticky header when the page is scrolled', async () => {
    createComponent();
    global.pageYOffset = 100;
    triggerPageScroll();
    await nextTick();

    expect(findStickyHeader().exists()).toBe(true);
  });

  it('renders title, todos, and actions', () => {
    createComponent();

    expect(wrapper.findByText('Updated title').exists()).toBe(true);
    expect(findWorkItemTodos().exists()).toBe(true);
    expect(findWorkItemActions().exists()).toBe(true);
  });

  describe('confidential badge', () => {
    describe('when not confidential', () => {
      beforeEach(() => {
        createComponent({ confidential: false });
      });

      it('does not render', () => {
        expect(findConfidentialityBadge().exists()).toBe(false);
      });
    });

    describe('when confidential', () => {
      beforeEach(() => {
        createComponent({ confidential: true });
      });

      it('renders', () => {
        expect(findConfidentialityBadge().exists()).toBe(true);
      });
    });
  });

  describe('locked badge', () => {
    describe('when discussion is not locked', () => {
      beforeEach(() => {
        createComponent({ discussionLocked: false });
      });

      it('does not render', () => {
        expect(findLockedBadge().exists()).toBe(false);
      });
    });

    describe('when discussion is locked', () => {
      beforeEach(() => {
        createComponent({ discussionLocked: true });
      });

      it('renders', () => {
        expect(findLockedBadge().exists()).toBe(true);
      });
    });
  });
});
