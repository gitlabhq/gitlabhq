import { shallowMount } from '@vue/test-utils';

import { listObj } from 'jest/boards/mock_data';
import BoardColumn from '~/boards/components/board_column_new.vue';
import List from '~/boards/models/list';
import { ListType } from '~/boards/constants';
import { createStore } from '~/boards/stores';

describe('Board Column Component', () => {
  let wrapper;
  let store;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const createComponent = ({ listType = ListType.backlog, collapsed = false } = {}) => {
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

    store = createStore();

    wrapper = shallowMount(BoardColumn, {
      store,
      propsData: {
        disabled: false,
        list,
      },
      provide: {
        boardId,
      },
    });
  };

  const isExpandable = () => wrapper.classes('is-expandable');
  const isCollapsed = () => wrapper.classes('is-collapsed');

  describe('Given different list types', () => {
    it('is expandable when List Type is `backlog`', () => {
      createComponent({ listType: ListType.backlog });

      expect(isExpandable()).toBe(true);
    });
  });

  describe('expanded / collapsed column', () => {
    it('has class is-collapsed when list is collapsed', () => {
      createComponent({ collapsed: false });

      expect(wrapper.vm.list.isExpanded).toBe(true);
    });

    it('does not have class is-collapsed when list is expanded', () => {
      createComponent({ collapsed: true });

      expect(isCollapsed()).toBe(true);
    });
  });
});
