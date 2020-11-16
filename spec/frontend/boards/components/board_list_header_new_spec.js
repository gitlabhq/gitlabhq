import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';

import { listObj } from 'jest/boards/mock_data';
import BoardListHeader from '~/boards/components/board_list_header_new.vue';
import List from '~/boards/models/list';
import { ListType } from '~/boards/constants';

const localVue = createLocalVue();

localVue.use(Vuex);

describe('Board List Header Component', () => {
  let wrapper;
  let store;

  const updateListSpy = jest.fn();

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    localStorage.clear();
  });

  const createComponent = ({
    listType = ListType.backlog,
    collapsed = false,
    withLocalStorage = true,
    currentUserId = null,
  } = {}) => {
    const boardId = '1';

    const listMock = {
      ...listObj,
      list_type: listType,
      collapsed,
    };

    if (listType === ListType.assignee) {
      delete listMock.label;
      listMock.user = {};
    }

    const list = new List({ ...listMock, doNotFetchIssues: true });

    if (withLocalStorage) {
      localStorage.setItem(
        `boards.${boardId}.${list.type}.${list.id}.expanded`,
        (!collapsed).toString(),
      );
    }

    store = new Vuex.Store({
      state: {},
      actions: { updateList: updateListSpy },
      getters: {},
    });

    wrapper = shallowMount(BoardListHeader, {
      store,
      localVue,
      propsData: {
        disabled: false,
        list,
      },
      provide: {
        boardId,
        weightFeatureAvailable: false,
        currentUserId,
      },
    });
  };

  const isExpanded = () => wrapper.vm.list.isExpanded;
  const isCollapsed = () => !isExpanded();

  const findAddIssueButton = () => wrapper.find({ ref: 'newIssueBtn' });
  const findCaret = () => wrapper.find('.board-title-caret');

  describe('Add issue button', () => {
    const hasNoAddButton = [ListType.promotion, ListType.blank, ListType.closed];
    const hasAddButton = [ListType.backlog, ListType.label, ListType.milestone, ListType.assignee];

    it.each(hasNoAddButton)('does not render when List Type is `%s`', listType => {
      createComponent({ listType });

      expect(findAddIssueButton().exists()).toBe(false);
    });

    it.each(hasAddButton)('does render when List Type is `%s`', listType => {
      createComponent({ listType });

      expect(findAddIssueButton().exists()).toBe(true);
    });

    it('has a test for each list type', () => {
      createComponent();

      Object.values(ListType).forEach(value => {
        expect([...hasAddButton, ...hasNoAddButton]).toContain(value);
      });
    });

    it('does render when logged out', () => {
      createComponent();

      expect(findAddIssueButton().exists()).toBe(true);
    });
  });

  describe('expanding / collapsing the column', () => {
    it('does not collapse when clicking the header', async () => {
      createComponent();

      expect(isCollapsed()).toBe(false);

      wrapper.find('[data-testid="board-list-header"]').trigger('click');

      await wrapper.vm.$nextTick();

      expect(isCollapsed()).toBe(false);
    });

    it('collapses expanded Column when clicking the collapse icon', async () => {
      createComponent();

      expect(isExpanded()).toBe(true);

      findCaret().vm.$emit('click');

      await wrapper.vm.$nextTick();

      expect(isCollapsed()).toBe(true);
    });

    it('expands collapsed Column when clicking the expand icon', async () => {
      createComponent({ collapsed: true });

      expect(isCollapsed()).toBe(true);

      findCaret().vm.$emit('click');

      await wrapper.vm.$nextTick();

      expect(isCollapsed()).toBe(false);
    });

    it("when logged in it calls list update and doesn't set localStorage", async () => {
      createComponent({ withLocalStorage: false, currentUserId: 1 });

      findCaret().vm.$emit('click');
      await wrapper.vm.$nextTick();

      expect(updateListSpy).toHaveBeenCalledTimes(1);
      expect(localStorage.getItem(`${wrapper.vm.uniqueKey}.expanded`)).toBe(null);
    });

    it("when logged out it doesn't call list update and sets localStorage", async () => {
      createComponent();

      findCaret().vm.$emit('click');
      await wrapper.vm.$nextTick();

      expect(updateListSpy).not.toHaveBeenCalled();
      expect(localStorage.getItem(`${wrapper.vm.uniqueKey}.expanded`)).toBe(String(isExpanded()));
    });
  });
});
