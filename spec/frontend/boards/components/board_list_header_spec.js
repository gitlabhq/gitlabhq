import { GlButtonGroup, GlAnimatedChevronLgRightDownIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  boardListQueryResponse,
  mockLabelList,
  updateBoardListResponse,
  mockMilestoneQueryResponse,
  mockMilestoneQueryList,
} from 'jest/boards/mock_data';
import { parseBoolean } from '~/lib/utils/common_utils';
import BoardListHeader from '~/boards/components/board_list_header.vue';
import MilestonePopover from '~/issuable/popover/components/milestone_popover.vue';
import updateBoardListMutation from '~/boards/graphql/board_list_update.mutation.graphql';
import { ListType } from '~/boards/constants';
import * as cacheUpdates from '~/boards/graphql/cache_updates';
import listQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';
import milestoneQuery from '~/issuable/popover/queries/milestone.query.graphql';

Vue.use(VueApollo);
jest.mock('@gitlab/ui/src/components/base/icon/icon.vue', () => ({
  name: 'GlIcon',
  props: ['name'],
  template: '<span :data-icon="name"></span>',
}));

describe('Board List Header Component', () => {
  let wrapper;
  let fakeApollo;

  const mockClientToggleListCollapsedResolver = jest.fn();
  const updateListHandlerSuccess = jest.fn().mockResolvedValue(updateBoardListResponse);

  beforeEach(() => {
    cacheUpdates.setError = jest.fn();
  });

  afterEach(() => {
    fakeApollo = null;

    localStorage.clear();
  });

  const createComponent = ({
    listType = ListType.backlog,
    collapsed = false,
    withLocalStorage = true,
    currentUserId = 1,
    listQueryHandler = jest.fn().mockResolvedValue(boardListQueryResponse()),
    updateListHandler = updateListHandlerSuccess,
    injectedProps = {},
    mountFn = shallowMountExtended,
    additionalApolloMocks = [],
    list = null,
  } = {}) => {
    const boardId = 'gid://gitlab/Board/1';

    const listMock = list || {
      ...mockLabelList,
      listType,
      collapsed,
    };

    if (!list && listType === ListType.assignee) {
      delete listMock.label;
      listMock.assignee = {};
    }

    if (withLocalStorage && listMock.listType && listMock.id) {
      localStorage.setItem(
        `boards.${boardId}.${listMock.listType}.${listMock.id}.collapsed`,
        collapsed.toString(),
      );
    }

    const apolloMocks = [
      [listQuery, listQueryHandler],
      [updateBoardListMutation, updateListHandler],
      ...additionalApolloMocks,
    ];

    fakeApollo = createMockApollo(apolloMocks, {
      Mutation: {
        clientToggleListCollapsed: mockClientToggleListCollapsedResolver,
      },
    });

    const mountOptions = {
      apolloProvider: fakeApollo,
      propsData: {
        list: listMock,
        filterParams: {},
        boardId,
      },
      provide: {
        weightFeatureAvailable: false,
        currentUserId,
        isEpicBoard: false,
        disabled: false,
        ...injectedProps,
      },
      stubs: {
        GlButtonGroup,
        GlIcon: true,
        MilestonePopover: true,
      },
    };
    wrapper = mountFn(BoardListHeader, mountOptions);
  };

  const findButtonGroup = () => wrapper.findComponent(GlButtonGroup);
  const isCollapsed = () => wrapper.vm.list.collapsed;
  const findTitle = () => wrapper.find('.board-title');
  const findCaret = () => wrapper.findByTestId('board-title-caret');
  const findNewIssueButton = () => wrapper.findByTestId('new-issue-btn');
  const findSettingsButton = () => wrapper.findByTestId('settings-btn');
  const findBoardListHeader = () => wrapper.findByTestId('board-list-header');
  const findMilestoneTrigger = () => wrapper.findByTestId('milestone-trigger');
  const findMilestonePopover = () => wrapper.findComponent(MilestonePopover);

  it('renders border when label color is present', () => {
    const expected = [
      'gl-border-t-solid',
      'gl-border-4',
      'gl-rounded-tl-base',
      'gl-rounded-tr-base',
    ];

    createComponent({ listType: ListType.label });

    expect(findBoardListHeader().classes()).toEqual(expect.arrayContaining(expected));
  });

  describe('Add issue button', () => {
    const hasNoAddButton = [ListType.closed];
    const hasAddButton = [
      ListType.backlog,
      ListType.label,
      ListType.milestone,
      ListType.iteration,
      ListType.assignee,
      ListType.status,
    ];

    it.each(hasNoAddButton)('does not render dropdown when List Type is `%s`', (listType) => {
      createComponent({ listType });

      expect(findButtonGroup().exists()).toBe(false);
    });

    it.each(hasAddButton)('does render when List Type is `%s`', (listType) => {
      createComponent({ listType });

      expect(findButtonGroup().exists()).toBe(true);
      expect(findNewIssueButton().exists()).toBe(true);
    });

    it('does not render dropdown when logged out', () => {
      createComponent({
        currentUserId: null,
      });

      expect(findButtonGroup().exists()).toBe(false);
    });
  });

  describe('Milestone popover', () => {
    const createMilestoneComponent = (props = {}) => {
      const milestoneListMock = {
        ...mockMilestoneQueryList,
        ...props,
      };

      const milestoneQueryHandler = jest.fn().mockResolvedValue(mockMilestoneQueryResponse);

      createComponent({
        list: milestoneListMock,
        listType: ListType.milestone,
        mountFn: mountExtended,
        additionalApolloMocks: [[milestoneQuery, milestoneQueryHandler]],
      });
    };

    it('does not render MilestonePopover initially', () => {
      createMilestoneComponent();
      expect(findMilestonePopover().exists()).toBe(false);
    });

    it('renders MilestonePopover when hovering over milestone trigger', async () => {
      createMilestoneComponent();

      const milestoneTrigger = findMilestoneTrigger();
      await milestoneTrigger.trigger('mouseenter');
      await nextTick();
      expect(findMilestonePopover().exists()).toBe(true);

      expect(findMilestonePopover().exists()).toBe(true);
      expect(findMilestonePopover().props('milestoneId')).toBe(mockMilestoneQueryList.milestone.id);
      expect(findMilestonePopover().props('cachedTitle')).toBe(mockMilestoneQueryList.title);
      expect(findMilestonePopover().props('placement')).toBe('bottom');
    });

    it('hides MilestonePopover when mouse leaves milestone trigger', async () => {
      createMilestoneComponent();

      const milestoneTrigger = findMilestoneTrigger();

      // Show popover
      await milestoneTrigger.trigger('mouseenter');
      await nextTick();
      expect(findMilestonePopover().exists()).toBe(true);

      // Hide popover
      await milestoneTrigger.trigger('mouseleave');
      await nextTick();
      expect(findMilestonePopover().exists()).toBe(false);
    });

    it('does not render for non-milestone lists', () => {
      createComponent({ listType: ListType.label });
      expect(findMilestonePopover().exists()).toBe(false);
    });
  });

  describe('Settings Button', () => {
    const hasSettings = [ListType.assignee, ListType.milestone, ListType.iteration, ListType.label];

    it.each(hasSettings)('does render for List Type `%s`', (listType) => {
      createComponent({ listType });

      expect(findButtonGroup().exists()).toBe(true);
      expect(findSettingsButton().exists()).toBe(true);
    });

    it('does not render dropdown when ListType `closed`', () => {
      createComponent({ listType: ListType.closed });

      expect(findButtonGroup().exists()).toBe(false);
    });

    it('renders dropdown but not the Settings button when ListType `backlog`', () => {
      createComponent({ listType: ListType.backlog });

      expect(findButtonGroup().exists()).toBe(true);
      expect(findSettingsButton().exists()).toBe(false);
    });
  });

  describe('expanding / collapsing the column', () => {
    it('should display collapse icon when column is expanded', () => {
      createComponent();

      const icon = findCaret().findComponent(GlAnimatedChevronLgRightDownIcon);

      // Vue compat doesn't know about component props if it extends other component
      expect(icon.props('isOn') ?? parseBoolean(icon.attributes('is-on'))).toBe(true);
    });

    it('should display expand icon when column is collapsed', () => {
      createComponent({ collapsed: true });

      const icon = findCaret().findComponent(GlAnimatedChevronLgRightDownIcon);

      // Vue compat doesn't know about component props if it extends other component
      expect(icon.props('isOn') ?? parseBoolean(icon.attributes('is-on'))).toBe(false);
    });

    it('set active board item on client when clicking on card', async () => {
      createComponent({ listType: ListType.label });
      await nextTick();

      findCaret().vm.$emit('click');
      await nextTick();

      expect(mockClientToggleListCollapsedResolver).toHaveBeenCalledWith(
        {},
        {
          list: mockLabelList,
          collapsed: true,
        },
        expect.anything(),
        expect.anything(),
      );
    });

    it("when logged in it doesn't set localStorage", async () => {
      createComponent({ withLocalStorage: false, currentUserId: 1 });

      findCaret().vm.$emit('click');
      await nextTick();

      expect(localStorage.getItem(`${wrapper.vm.uniqueKey}.collapsed`)).toBe(null);
    });

    it('when logged out it sets localStorage', async () => {
      createComponent({
        currentUserId: null,
      });

      findCaret().vm.$emit('click');
      await nextTick();

      expect(localStorage.getItem(`${wrapper.vm.uniqueKey}.collapsed`)).toBe(
        String(!isCollapsed()),
      );
    });
  });

  describe('user can drag', () => {
    const cannotDragList = [ListType.backlog, ListType.closed];
    const canDragList = [ListType.label, ListType.milestone, ListType.iteration, ListType.assignee];

    it.each(cannotDragList)(
      'does not have gl-cursor-grab class so user cannot drag list',
      (listType) => {
        createComponent({ listType });

        expect(findTitle().classes()).not.toContain('gl-cursor-grab');
      },
    );

    it.each(canDragList)('has gl-cursor-grab class so user can drag list', (listType) => {
      createComponent({ listType });

      expect(findTitle().classes()).toContain('gl-cursor-grab');
    });
  });

  describe('collapse/expand mutations', () => {
    it('does not call update list mutation when user is not logged in', async () => {
      createComponent({ currentUserId: null });

      findCaret().vm.$emit('click');
      await nextTick();

      expect(updateListHandlerSuccess).not.toHaveBeenCalled();
    });

    it('calls update list mutation when user is logged in', async () => {
      createComponent({ currentUserId: 1 });

      findCaret().vm.$emit('click');
      await nextTick();

      expect(updateListHandlerSuccess).toHaveBeenCalledWith(
        expect.objectContaining({
          listId: 'gid://gitlab/List/2',
          collapsed: true,
        }),
      );
    });
  });

  describe('when fetch list query fails', () => {
    const errorMessage = 'Failed to fetch list';
    const listQueryHandlerFailure = jest.fn().mockRejectedValue(new Error(errorMessage));

    beforeEach(() => {
      createComponent({
        listQueryHandler: listQueryHandlerFailure,
      });
    });

    it('sets error', async () => {
      await waitForPromises();

      expect(cacheUpdates.setError).toHaveBeenCalled();
    });
  });

  describe('when update list mutation fails', () => {
    const errorMessage = 'Failed to update list';
    const updateListHandlerFailure = jest.fn().mockRejectedValue(new Error(errorMessage));

    beforeEach(() => {
      createComponent({
        currentUserId: 1,
        updateListHandler: updateListHandlerFailure,
      });
    });

    it('sets error', async () => {
      await waitForPromises();

      findCaret().vm.$emit('click');
      await waitForPromises();

      expect(cacheUpdates.setError).toHaveBeenCalled();
    });
  });
});
