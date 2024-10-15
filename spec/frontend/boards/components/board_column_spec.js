import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import { listObj } from 'jest/boards/mock_data';
import BoardColumn from '~/boards/components/board_column.vue';
import BoardList from '~/boards/components/board_list.vue';
import { ListType } from '~/boards/constants';
import BoardAddNewColumnBetween from '~/boards/components/board_add_new_column_between.vue';

describe('Board Column Component', () => {
  let wrapper;

  const createComponent = ({
    listType = ListType.backlog,
    collapsed = false,
    highlightedLists = [],
    canAdminList,
    last,
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
        listQueryVariables: {},
        filters: {},
        highlightedLists,
        canAdminList,
        last,
      },
      stubs: {
        BoardAddNewColumnBetween,
      },
    });
  };

  const isExpandable = () => wrapper.find('.is-expandable').exists();
  const isCollapsed = () => wrapper.find('.is-collapsed').exists();
  const findList = () => wrapper.findComponent(BoardList);
  const findAddColumnBetween = () =>
    wrapper.find('[data-testid="board-add-new-column-between-button"]');

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

  describe('add new column between button', () => {
    it('BoardAddNewColumnBetween is rendered if use can admin list, the list is not last, and the new list form is not showing', () => {
      createComponent({
        canAdminList: true,
        last: false,
      });

      expect(findAddColumnBetween().exists()).toBe(true);
    });

    it('BoardAddNewColumnBetween is not rendered if use cannot admin list', () => {
      createComponent({
        canAdminList: false,
        last: false,
      });

      expect(findAddColumnBetween().exists()).toBe(false);
    });

    it('BoardAddNewColumnBetween is not rendered if list is last', () => {
      createComponent({
        canAdminList: true,
        showNewListForm: false,
        last: true,
      });

      expect(findAddColumnBetween().exists()).toBe(false);
    });

    it('BoardAddNewColumnBetween is showNewListForm is true', async () => {
      createComponent({
        canAdminList: true,
        last: false,
      });

      expect(findAddColumnBetween().exists()).toBe(true);

      wrapper.vm.setShowNewListAfter(true);

      await nextTick();

      expect(findAddColumnBetween().exists()).toBe(false);
    });
  });

  it('emits `cannot-find-active-item` when `BoardList` emits `cannot-find-active-item`', () => {
    createComponent();

    findList().vm.$emit('cannot-find-active-item');

    expect(wrapper.emitted('cannot-find-active-item')).toHaveLength(1);
  });
});
