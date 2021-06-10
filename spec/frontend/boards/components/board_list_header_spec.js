import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

import { mockLabelList } from 'jest/boards/mock_data';
import BoardListHeader from '~/boards/components/board_list_header.vue';
import { ListType } from '~/boards/constants';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('Board List Header Component', () => {
  let wrapper;
  let store;

  const updateListSpy = jest.fn();
  const toggleListCollapsedSpy = jest.fn();

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    localStorage.clear();
  });

  const createComponent = ({
    listType = ListType.backlog,
    collapsed = false,
    withLocalStorage = true,
    currentUserId = 1,
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
      getters: { isEpicBoard: () => false },
    });

    wrapper = extendedWrapper(
      shallowMount(BoardListHeader, {
        store,
        localVue,
        propsData: {
          disabled: false,
          list: listMock,
        },
        provide: {
          boardId,
          weightFeatureAvailable: false,
          currentUserId,
        },
      }),
    );
  };

  const isCollapsed = () => wrapper.vm.list.collapsed;

  const findAddIssueButton = () => wrapper.find({ ref: 'newIssueBtn' });
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

      expect(icon.props('icon')).toBe('chevron-right');
    });

    it('should display expand icon when column is collapsed', async () => {
      createComponent({ collapsed: true });

      const icon = findCaret();

      expect(icon.props('icon')).toBe('chevron-down');
    });

    it('should dispatch toggleListCollapse when clicking the collapse icon', async () => {
      createComponent();

      findCaret().vm.$emit('click');

      await wrapper.vm.$nextTick();
      expect(toggleListCollapsedSpy).toHaveBeenCalledTimes(1);
    });

    it("when logged in it calls list update and doesn't set localStorage", async () => {
      createComponent({ withLocalStorage: false, currentUserId: 1 });

      findCaret().vm.$emit('click');
      await wrapper.vm.$nextTick();

      expect(updateListSpy).toHaveBeenCalledTimes(1);
      expect(localStorage.getItem(`${wrapper.vm.uniqueKey}.collapsed`)).toBe(null);
    });

    it("when logged out it doesn't call list update and sets localStorage", async () => {
      createComponent({
        currentUserId: null,
      });

      findCaret().vm.$emit('click');
      await wrapper.vm.$nextTick();

      expect(updateListSpy).not.toHaveBeenCalled();
      expect(localStorage.getItem(`${wrapper.vm.uniqueKey}.collapsed`)).toBe(String(isCollapsed()));
    });
  });

  describe('user can drag', () => {
    const cannotDragList = [ListType.backlog, ListType.closed];
    const canDragList = [ListType.label, ListType.milestone, ListType.iteration, ListType.assignee];

    it.each(cannotDragList)(
      'does not have user-can-drag-class so user cannot drag list',
      (listType) => {
        createComponent({ listType });

        expect(findTitle().classes()).not.toContain('user-can-drag');
      },
    );

    it.each(canDragList)('has user-can-drag-class so user can drag list', (listType) => {
      createComponent({ listType });

      expect(findTitle().classes()).toContain('user-can-drag');
    });
  });
});
