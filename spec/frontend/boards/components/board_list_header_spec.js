import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  boardListQueryResponse,
  mockLabelList,
  updateBoardListResponse,
} from 'jest/boards/mock_data';
import BoardListHeader from '~/boards/components/board_list_header.vue';
import updateBoardListMutation from '~/boards/graphql/board_list_update.mutation.graphql';
import { ListType } from '~/boards/constants';
import listQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';

Vue.use(VueApollo);
Vue.use(Vuex);

describe('Board List Header Component', () => {
  let wrapper;
  let store;
  let fakeApollo;

  const updateListSpy = jest.fn();
  const toggleListCollapsedSpy = jest.fn();
  const mockClientToggleListCollapsedResolver = jest.fn();
  const updateListHandler = jest.fn().mockResolvedValue(updateBoardListResponse);

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

    store = new Vuex.Store({
      state: {},
      actions: { updateList: updateListSpy, toggleListCollapsed: toggleListCollapsedSpy },
    });
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
      store,
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
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const isCollapsed = () => wrapper.vm.list.collapsed;
  const findTitle = () => wrapper.find('.board-title');
  const findCaret = () => wrapper.findByTestId('board-title-caret');
  const findNewIssueButton = () => wrapper.findByTestId('newIssueBtn');
  const findSettingsButton = () => wrapper.findByTestId('settingsBtn');

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

      expect(findDropdown().exists()).toBe(false);
    });

    it.each(hasAddButton)('does render when List Type is `%s`', (listType) => {
      createComponent({ listType });

      expect(findDropdown().exists()).toBe(true);
      expect(findNewIssueButton().exists()).toBe(true);
    });

    it('does not render dropdown when logged out', () => {
      createComponent({
        currentUserId: null,
      });

      expect(findDropdown().exists()).toBe(false);
    });
  });

  describe('Settings Button', () => {
    const hasSettings = [ListType.assignee, ListType.milestone, ListType.iteration, ListType.label];

    it.each(hasSettings)('does render for List Type `%s`', (listType) => {
      createComponent({ listType });

      expect(findDropdown().exists()).toBe(true);
      expect(findSettingsButton().exists()).toBe(true);
    });

    it('does not render dropdown when ListType `closed`', () => {
      createComponent({ listType: ListType.closed });

      expect(findDropdown().exists()).toBe(false);
    });

    it('renders dropdown but not the Settings button when ListType `backlog`', () => {
      createComponent({ listType: ListType.backlog });

      expect(findDropdown().exists()).toBe(true);
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

    it('should dispatch toggleListCollapse when clicking the collapse icon', async () => {
      createComponent();

      findCaret().vm.$emit('click');

      await nextTick();
      expect(toggleListCollapsedSpy).toHaveBeenCalledTimes(1);
    });

    it("when logged in it calls list update and doesn't set localStorage", async () => {
      createComponent({ withLocalStorage: false, currentUserId: 1 });

      findCaret().vm.$emit('click');
      await nextTick();

      expect(updateListSpy).toHaveBeenCalledTimes(1);
      expect(localStorage.getItem(`${wrapper.vm.uniqueKey}.collapsed`)).toBe(null);
    });

    it("when logged out it doesn't call list update and sets localStorage", async () => {
      createComponent({
        currentUserId: null,
      });

      findCaret().vm.$emit('click');
      await nextTick();

      expect(updateListSpy).not.toHaveBeenCalled();
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

  describe('Apollo boards', () => {
    beforeEach(async () => {
      createComponent({ listType: ListType.label, injectedProps: { isApolloBoard: true } });
      await nextTick();
    });

    it('set active board item on client when clicking on card', async () => {
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

    it('does not call update list mutation when user is not logged in', async () => {
      createComponent({ currentUserId: null, injectedProps: { isApolloBoard: true } });

      findCaret().vm.$emit('click');
      await nextTick();

      expect(updateListHandler).not.toHaveBeenCalled();
    });

    it('calls update list mutation when user is logged in', async () => {
      createComponent({ currentUserId: 1, injectedProps: { isApolloBoard: true } });

      findCaret().vm.$emit('click');
      await nextTick();

      expect(updateListHandler).toHaveBeenCalledWith({ listId: mockLabelList.id, collapsed: true });
    });
  });
});
