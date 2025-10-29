import { GlIntersectionObserver, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { STATE_OPEN, STATE_CLOSED } from '~/work_items/constants';
import { issueType, taskType, workItemResponseFactory } from 'ee_else_ce_jest/work_items/mock_data';
import HiddenBadge from '~/issuable/components/hidden_badge.vue';
import LockedBadge from '~/issuable/components/locked_badge.vue';
import ArchivedBadge from '~/issuable/components/archived_badge.vue';
import WorkItemStickyHeader from '~/work_items/components/work_item_sticky_header.vue';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import TodosToggle from '~/work_items/components/shared/todos_toggle.vue';
import WorkItemStateBadge from '~/work_items/components/work_item_state_badge.vue';
import WorkItemNotificationsWidget from '~/work_items/components/work_item_notifications_widget.vue';

describe('WorkItemStickyHeader', () => {
  let wrapper;

  const createComponent = ({
    confidential = false,
    hidden = false,
    imported = false,
    discussionLocked = false,
    canUpdate = true,
    features = {},
    movedToWorkItemUrl = null,
    duplicatedToWorkItemUrl = null,
    promotedToEpicUrl = null,
    slots = {},
    isDrawer = false,
    isStickyHeaderShowing = true,
    archived = false,
    workItemState = STATE_OPEN,
    workItemType = taskType,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemStickyHeader, {
      propsData: {
        workItem: workItemResponseFactory({
          canUpdate,
          confidential,
          discussionLocked,
          hidden,
          imported,
          movedToWorkItemUrl,
          duplicatedToWorkItemUrl,
          promotedToEpicUrl,
          workItemType,
        }).data.workItem,
        isStickyHeaderShowing,
        updateInProgress: false,
        showWorkItemCurrentUserTodos: true,
        currentUserTodos: [],
        workItemState,
        isDrawer,
        archived,
      },
      provide: {
        glFeatures: {
          ...features,
        },
      },
      slots,
    });
  };

  const findStickyHeader = () => wrapper.findByTestId('work-item-sticky-header');
  const findConfidentialityBadge = () => wrapper.findComponent(ConfidentialityBadge);
  const findHiddenBadge = () => wrapper.findComponent(HiddenBadge);
  const findImportedBadge = () => wrapper.findComponent(ImportedBadge);
  const findLockedBadge = () => wrapper.findComponent(LockedBadge);
  const findArchivedBadge = () => wrapper.findComponent(ArchivedBadge);
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

  it('renders title and todos', () => {
    createComponent();

    expect(findWorkItemTitle().exists()).toBe(true);
    expect(findTodosToggle().exists()).toBe(true);
  });

  it('renders the actions slot content when sticky header is showing', () => {
    createComponent({
      slots: {
        actions: '<div class="mock-actions">Mock Actions Content</div>',
      },
    });

    const actionsSlot = wrapper.find('.mock-actions');
    expect(actionsSlot.exists()).toBe(true);
    expect(actionsSlot.text()).toBe('Mock Actions Content');
  });

  it('has title with the link to the top', () => {
    createComponent();
    expect(findWorkItemTitle().attributes('href')).toBe('#top');
  });

  it('renders the state badge', () => {
    createComponent();
    expect(findWorkItemStateBadge().exists()).toBe(true);
  });

  describe('positioning classes', () => {
    it('applies absolute positioning classes when isDrawer is true', () => {
      createComponent({ isDrawer: true });

      const stickyHeader = findStickyHeader();
      expect(stickyHeader.classes()).toContain('gl-absolute');
      expect(stickyHeader.classes()).toContain('gl-left-0');
      expect(stickyHeader.classes()).toContain('gl-top-10');
      expect(stickyHeader.classes()).not.toContain('gl-fixed');
    });

    it('applies fixed positioning classes when isDrawer is false', () => {
      createComponent({ isDrawer: false });

      const stickyHeader = findStickyHeader();
      expect(stickyHeader.classes()).toContain('gl-fixed');
      expect(stickyHeader.classes()).not.toContain('gl-absolute');
      expect(stickyHeader.classes()).not.toContain('gl-left-0');
      expect(stickyHeader.classes()).not.toContain('gl-top-10');
    });
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
  });

  describe('WorkItemStateBadge props', () => {
    it('passes URL props correctly when they exist', async () => {
      // We'll never populate all of these attributes because
      // a work item can only have one closed reason.
      // For simplicity we're passing all of them to easily assert
      // that the props are passed correctly.
      const workItemAttributes = {
        movedToWorkItemUrl: 'http://example.com/moved',
        duplicatedToWorkItemUrl: 'http://example.com/duplicated',
        promotedToEpicUrl: 'http://example.com/epic',
      };

      await createComponent(workItemAttributes);

      const stateBadgeProps = findWorkItemStateBadge().props();
      Object.entries(workItemAttributes).forEach(([prop, url]) => {
        expect(stateBadgeProps[prop]).toBe(url);
      });
    });
  });

  describe('sticky header height', () => {
    beforeEach(() => {
      // Ensure a clean slate for the CSS variable
      document.documentElement.style.removeProperty('--work-item-sticky-header-height');
    });

    afterEach(() => {
      jest.restoreAllMocks();
    });

    it('sets the CSS variable with the measured height', async () => {
      createComponent();

      const stickyHeaderEl = findStickyHeader().element;
      jest.spyOn(stickyHeaderEl, 'offsetHeight', 'get').mockReturnValue(64);

      wrapper.vm.syncStickyHeaderHeight();
      await nextTick();

      expect(
        document.documentElement.style.getPropertyValue('--work-item-sticky-header-height').trim(),
      ).toBe('64px');
    });

    it('invokes on mount when sticky header is shown initially', async () => {
      const spy = jest.spyOn(WorkItemStickyHeader.methods, 'syncStickyHeaderHeight');
      createComponent({ isStickyHeaderShowing: true });

      await nextTick();
      await nextTick();

      expect(spy).toHaveBeenCalled();
    });

    it('invokes when isStickyHeaderShowing toggles from false to true', async () => {
      createComponent({ isStickyHeaderShowing: false });
      const spy = jest.spyOn(wrapper.vm, 'syncStickyHeaderHeight');

      await wrapper.setProps({ isStickyHeaderShowing: true });
      await nextTick();
      await nextTick();

      expect(spy).toHaveBeenCalled();
    });
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

  describe('archived and status badge', () => {
    describe.each`
      archived | workItemState   | archivedBadgeExists | stateBadgeExists | description
      ${false} | ${undefined}    | ${false}            | ${true}          | ${'when not archived'}
      ${true}  | ${undefined}    | ${true}             | ${false}         | ${'when archived'}
      ${true}  | ${STATE_OPEN}   | ${true}             | ${false}         | ${'when archived and work item is open'}
      ${true}  | ${STATE_CLOSED} | ${true}             | ${false}         | ${'when archived and work item is closed'}
      ${false} | ${STATE_OPEN}   | ${false}            | ${true}          | ${'when not archived and work item is open'}
      ${false} | ${STATE_CLOSED} | ${false}            | ${true}          | ${'when not archived and work item is closed'}
    `('$description', ({ archived, workItemState, archivedBadgeExists, stateBadgeExists }) => {
      beforeEach(() => {
        createComponent({ archived, workItemState });
      });

      it(`${archivedBadgeExists ? 'renders' : 'does not render'} archived badge`, () => {
        expect(findArchivedBadge().exists()).toBe(archivedBadgeExists);
      });

      it(`${stateBadgeExists ? 'renders' : 'does not render'} state badge`, () => {
        expect(findWorkItemStateBadge().exists()).toBe(stateBadgeExists);
      });
    });

    describe('when archived', () => {
      beforeEach(() => {
        createComponent({ archived: true, workItemType: issueType });
      });

      it('passes correct issuable type to archived badge', () => {
        expect(findArchivedBadge().props('issuableType')).toBe('Issue');
      });
    });
  });

  describe('hidden badge', () => {
    it('renders when the work item is hidden', () => {
      createComponent({ hidden: true });

      expect(findHiddenBadge().exists()).toBe(true);
    });

    it('does not render when the work item is not hidden', () => {
      createComponent({ hidden: false });

      expect(findHiddenBadge().exists()).toBe(false);
    });
  });

  describe('imported badge', () => {
    it('renders when the work item is imported', () => {
      createComponent({ imported: true });

      expect(findImportedBadge().exists()).toBe(true);
    });

    it('does not render when the work item is not imported', () => {
      createComponent({ imported: false });

      expect(findImportedBadge().exists()).toBe(false);
    });
  });
});
