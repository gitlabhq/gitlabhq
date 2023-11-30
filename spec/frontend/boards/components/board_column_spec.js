import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';

import { listObj } from 'jest/boards/mock_data';
import BoardColumn from '~/boards/components/board_column.vue';
import { ListType } from '~/boards/constants';

describe('Board Column Component', () => {
  let wrapper;

  const createComponent = ({
    listType = ListType.backlog,
    collapsed = false,
    highlightedLists = [],
  } = {}) => {
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
      propsData: {
        list: listMock,
        boardId: 'gid://gitlab/Board/1',
        filters: {},
        highlightedLists,
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

      expect(isCollapsed()).toBe(false);
    });

    it('does not have class is-collapsed when list is expanded', () => {
      createComponent({ collapsed: true });

      expect(isCollapsed()).toBe(true);
    });
  });

  describe('highlighting', () => {
    it('scrolls to column when highlighted', async () => {
      createComponent({ highlightedLists: [listObj.id] });

      await nextTick();

      expect(wrapper.element.scrollIntoView).toHaveBeenCalled();
    });
  });
});
