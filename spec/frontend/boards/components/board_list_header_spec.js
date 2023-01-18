import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

import { boardListQueryResponse, mockLabelList } from 'jest/boards/mock_data';
import BoardListHeader from '~/boards/components/board_list_header.vue';
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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    fakeApollo = null;

    localStorage.clear();
  });

  const createComponent = ({
    listType = ListType.backlog,
    collapsed = false,
    withLocalStorage = true,
    currentUserId = 1,
    listQueryHandler = jest.fn().mockResolvedValue(boardListQueryResponse()),
  } = {}) => {
    const boardId = '1';

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

    fakeApollo = createMockApollo([[listQuery, listQueryHandler]]);

    wrapper = extendedWrapper(
      shallowMount(BoardListHeader, {
        apolloProvider: fakeApollo,
        store,
        propsData: {
          list: listMock,
        },
        provide: {
          boardId,
          weightFeatureAvailable: false,
          currentUserId,
          isEpicBoard: false,
          disabled: false,
        },
      }),
    );
  };

  const isCollapsed = () => wrapper.vm.list.collapsed;

  const findAddIssueButton = () => wrapper.findComponent({ ref: 'newIssueBtn' });
  const findTitle = () => wrapper.find('.board-title');
  const findCaret = () => wrapper.findByTestId('board-title-caret');

  describe('Add issue button', () => {
    const hasNoAddButton = [ListType.closed];
    const hasAddButton = [
      ListType.backlog,
      ListType.label,
      ListType.milestone,
      ListType.iteration,
      ListType.assignee,
    ];

    it.each(hasNoAddButton)('does not render when List Type is `%s`', (listType) => {
      createComponent({ listType });

      expect(findAddIssueButton().exists()).toBe(false);
    });

    it.each(hasAddButton)('does render when List Type is `%s`', (listType) => {
      createComponent({ listType });

      expect(findAddIssueButton().exists()).toBe(true);
    });

    it('has a test for each list type', () => {
      createComponent();

      Object.values(ListType).forEach((value) => {
        expect([...hasAddButton, ...hasNoAddButton]).toContain(value);
      });
    });

    it('does not render when logged out', () => {
      createComponent({
        currentUserId: null,
      });

      expect(findAddIssueButton().exists()).toBe(false);
    });
  });

  describe('expanding / collapsing the column', () => {
    it('should display collapse icon when column is expanded', async () => {
      createComponent();

      const icon = findCaret();

      expect(icon.props('icon')).toBe('chevron-down');
    });

    it('should display expand icon when column is collapsed', async () => {
      createComponent({ collapsed: true });

      const icon = findCaret();

      expect(icon.props('icon')).toBe('chevron-right');
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
      expect(localStorage.getItem(`${wrapper.vm.uniqueKey}.collapsed`)).toBe(String(isCollapsed()));
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
});
