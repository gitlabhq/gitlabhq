import { GlButtonGroup } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  boardListQueryResponse,
  mockLabelList,
  updateBoardListResponse,
} from 'jest/boards/mock_data';
import BoardListHeader from '~/boards/components/board_list_header.vue';
import updateBoardListMutation from '~/boards/graphql/board_list_update.mutation.graphql';
import { ListType } from '~/boards/constants';
import * as cacheUpdates from '~/boards/graphql/cache_updates';
import listQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';

Vue.use(VueApollo);

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
  } = {}) => {
    const boardId = 'gid://gitlab/Board/1';

    const listMock = {
      ...mockLabelList,
      listType,
      collapsed,
    };

    if (listType === ListType.assignee) {
      delete listMock.label;
      listMock.assignee = {};
    }

    if (withLocalStorage) {
      localStorage.setItem(
        `boards.${boardId}.${listMock.listType}.${listMock.id}.collapsed`,
        collapsed.toString(),
      );
    }

    fakeApollo = createMockApollo(
      [
        [listQuery, listQueryHandler],
        [updateBoardListMutation, updateListHandler],
      ],
      {
        Mutation: {
          clientToggleListCollapsed: mockClientToggleListCollapsedResolver,
        },
      },
    );

    wrapper = shallowMountExtended(BoardListHeader, {
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
      },
    });
  };

  const findButtonGroup = () => wrapper.findComponent(GlButtonGroup);
  const isCollapsed = () => wrapper.vm.list.collapsed;
  const findTitle = () => wrapper.find('.board-title');
  const findCaret = () => wrapper.findByTestId('board-title-caret');
  const findNewIssueButton = () => wrapper.findByTestId('new-issue-btn');
  const findSettingsButton = () => wrapper.findByTestId('settings-btn');
  const findBoardListHeader = () => wrapper.findByTestId('board-list-header');

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

      const icon = findCaret();

      expect(icon.props('icon')).toBe('chevron-lg-down');
    });

    it('should display expand icon when column is collapsed', () => {
      createComponent({ collapsed: true });

      const icon = findCaret();

      expect(icon.props('icon')).toBe('chevron-lg-right');
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

  beforeEach(async () => {
    createComponent({ listType: ListType.label });
    await nextTick();
  });

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

    expect(updateListHandlerSuccess).toHaveBeenCalledWith({
      listId: mockLabelList.id,
      collapsed: true,
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
