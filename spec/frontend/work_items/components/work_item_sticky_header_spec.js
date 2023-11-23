import { GlIntersectionObserver } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { STATE_OPEN } from '~/work_items/constants';
import { workItemResponseFactory } from 'jest/work_items/mock_data';
import WorkItemStickyHeader from '~/work_items/components/work_item_sticky_header.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import WorkItemActions from '~/work_items/components/work_item_actions.vue';
import WorkItemTodos from '~/work_items/components/work_item_todos.vue';

describe('WorkItemStickyHeader', () => {
  let wrapper;

  const workItemResponse = workItemResponseFactory({ canUpdate: true, confidential: true }).data
    .workItem;

  const createComponent = () => {
    wrapper = shallowMountExtended(WorkItemStickyHeader, {
      propsData: {
        workItem: workItemResponse,
        fullPath: '/test',
        isStickyHeaderShowing: true,
        workItemNotificationsSubscribed: true,
        workItemParentId: null,
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
  const findWorkItemActions = () => wrapper.findComponent(WorkItemActions);
  const findWorkItemTodos = () => wrapper.findComponent(WorkItemTodos);
  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const triggerPageScroll = () => findIntersectionObserver().vm.$emit('disappear');

  beforeEach(() => {
    createComponent();
  });

  it('has the sticky header when the page is scrolled', async () => {
    global.pageYOffset = 100;
    triggerPageScroll();

    await nextTick();

    expect(findStickyHeader().exists()).toBe(true);
  });

  it('has the components of confidentiality, actions, todos and title', () => {
    expect(findConfidentialityBadge().exists()).toBe(true);
    expect(findWorkItemActions().exists()).toBe(true);
    expect(findWorkItemTodos().exists()).toBe(true);
    expect(wrapper.findByText(workItemResponse.title).exists()).toBe(true);
  });
});
