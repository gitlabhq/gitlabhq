import { GlIntersectionObserver, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { STATE_OPEN } from '~/work_items/constants';
import { workItemResponseFactory } from 'jest/work_items/mock_data';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import WorkItemStickyHeader from '~/work_items/components/work_item_sticky_header.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import WorkItemActions from '~/work_items/components/work_item_actions.vue';
import TodosToggle from '~/work_items/components/shared/todos_toggle.vue';
import WorkItemStateBadge from '~/work_items/components/work_item_state_badge.vue';
import WorkItemNotificationsWidget from '~/work_items/components/work_item_notifications_widget.vue';

describe('WorkItemStickyHeader', () => {
  let wrapper;

  const createComponent = ({
    confidential = false,
    discussionLocked = false,
    canUpdate = true,
    features = {},
    parentId = null,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemStickyHeader, {
      propsData: {
        workItem: workItemResponseFactory({ canUpdate, confidential, discussionLocked }).data
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
        isGroup: false,
        parentId,
      },
      provide: {
        glFeatures: {
          ...features,
        },
      },
    });
  };

  const findStickyHeader = () => wrapper.findByTestId('work-item-sticky-header');
  const findConfidentialityBadge = () => wrapper.findComponent(ConfidentialityBadge);
  const findLockedBadge = () => wrapper.findComponent(LockedBadge);
  const findWorkItemActions = () => wrapper.findComponent(WorkItemActions);
  const findTodosToggle = () => wrapper.findComponent(TodosToggle);
  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const findWorkItemStateBadge = () => wrapper.findComponent(WorkItemStateBadge);
  const findEditButton = () => wrapper.findByTestId('work-item-edit-button-sticky');
  const findWorkItemTitle = () => wrapper.findComponent(GlLink);
  const findWorkItemNotificationsWidget = () => wrapper.findComponent(WorkItemNotificationsWidget);
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

    expect(findWorkItemTitle().exists()).toBe(true);
    expect(findTodosToggle().exists()).toBe(true);
    expect(findWorkItemActions().exists()).toBe(true);
  });

  it('has title with the link to the top', () => {
    createComponent();
    expect(findWorkItemTitle().attributes('href')).toBe('#top');
  });

  it('renders the state badge', () => {
    createComponent();
    expect(findWorkItemStateBadge().exists()).toBe(true);
  });

  describe('edit button', () => {
    it('renders the button when it has permissions to edit', () => {
      createComponent({ canUpdate: true });

      expect(findEditButton().exists()).toBe(true);
    });

    it('does not render the button when it does not have permissions to edit', () => {
      createComponent({ canUpdate: false });

      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('notificationsTodosButtons Feature flag', () => {
    it.each`
      description        | featureFlag | expected
      ${'shows'}         | ${true}     | ${true}
      ${'does not show'} | ${false}    | ${false}
    `(
      '$description new notifications button when notificationsTodoButtons feature flag is $featureFlag',
      ({ featureFlag, expected }) => {
        createComponent({ features: { notificationsTodosButtons: featureFlag } });
        expect(findWorkItemNotificationsWidget().exists()).toBe(expected);
      },
    );

    it.each`
      description        | featureFlag | expected
      ${'hides'}         | ${true}     | ${true}
      ${'does not hide'} | ${false}    | ${false}
    `(
      '$description notifications toggle in actions menu when notificationsTodoButtons feature flag is $featureFlag',
      ({ featureFlag, expected }) => {
        createComponent({ features: { notificationsTodosButtons: featureFlag } });
        expect(findWorkItemActions().props().hideSubscribe).toBe(expected);
      },
    );
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

  it('passes the `parentId` prop down to the `WorkItemActions` component', () => {
    createComponent({ parentId: 'example-id' });

    expect(findWorkItemActions().props('parentId')).toBe('example-id');
  });
});
