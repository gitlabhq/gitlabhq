import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';

import { listObj } from 'jest/boards/mock_data';
import BoardColumn from '~/boards/components/board_column.vue';
import { ListType } from '~/boards/constants';
import { createStore } from '~/boards/stores';

describe('Board Column Component', () => {
  let wrapper;
  let store;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const initStore = () => {
    store = createStore();
  };

  const createComponent = ({ listType = ListType.backlog, collapsed = false } = {}) => {
    const boardId = '1';

    const listMock = {
      ...listObj,
      listType,
      collapsed,
    };

    if (listType === ListType.assignee) {
      delete listMock.label;
      listMock.assignee = {};
    }

    wrapper = shallowMount(BoardColumn, {
      store,
      propsData: {
        disabled: false,
        list: listMock,
      },
      provide: {
        boardId,
      },
    });
  };

  const isExpandable = () => wrapper.classes('is-expandable');
  const isCollapsed = () => wrapper.classes('is-collapsed');

  describe('Given different list types', () => {
    beforeEach(() => {
      initStore();
    });

    it('is expandable when List Type is `backlog`', () => {
      createComponent({ listType: ListType.backlog });

      expect(isExpandable()).toBe(true);
    });
  });

  describe('expanded / collapsed column', () => {
    it('has class is-collapsed when list is collapsed', () => {
      createComponent({ collapsed: false });

      expect(isCollapsed()).toBe(false);
    });

    it('does not have class is-collapsed when list is expanded', () => {
      createComponent({ collapsed: true });

      expect(isCollapsed()).toBe(true);
    });
  });

  describe('highlighting', () => {
    it('scrolls to column when highlighted', async () => {
      createComponent();

      store.state.highlightedLists.push(listObj.id);

      await nextTick();

      expect(wrapper.element.scrollIntoView).toHaveBeenCalled();
    });
  });

  describe('on mount', () => {
    beforeEach(async () => {
      initStore();
      jest.spyOn(store, 'dispatch').mockImplementation();
    });

    describe('when list is collapsed', () => {
      it('does not call fetchItemsForList when', async () => {
        createComponent({ collapsed: true });

        await nextTick();

        expect(store.dispatch).toHaveBeenCalledTimes(0);
      });
    });

    describe('when the list is not collapsed', () => {
      it('calls fetchItemsForList when', async () => {
        createComponent({ collapsed: false });

        await nextTick();

        expect(store.dispatch).toHaveBeenCalledWith('fetchItemsForList', { listId: 300 });
      });
    });
  });
});
