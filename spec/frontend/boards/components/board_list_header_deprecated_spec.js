import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import Vue from 'vue';

import { TEST_HOST } from 'helpers/test_constants';
import { listObj } from 'jest/boards/mock_data';
import BoardListHeader from '~/boards/components/board_list_header_deprecated.vue';
import { ListType } from '~/boards/constants';
import List from '~/boards/models/list';
import axios from '~/lib/utils/axios_utils';

describe('Board List Header Component', () => {
  let wrapper;
  let axiosMock;

  beforeEach(() => {
    window.gon = {};
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(`${TEST_HOST}/lists/1/issues`).reply(200, { issues: [] });
  });

  afterEach(() => {
    axiosMock.restore();

    wrapper.destroy();

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
      ...listObj,
      list_type: listType,
      collapsed,
    };

    if (listType === ListType.assignee) {
      delete listMock.label;
      listMock.user = {};
    }

    // Making List reactive
    const list = Vue.observable(new List(listMock));

    if (withLocalStorage) {
      localStorage.setItem(
        `boards.${boardId}.${list.type}.${list.id}.expanded`,
        (!collapsed).toString(),
      );
    }

    wrapper = shallowMount(BoardListHeader, {
      propsData: {
        disabled: false,
        list,
      },
      provide: {
        boardId,
        currentUserId,
      },
    });
  };

  const isCollapsed = () => !wrapper.props().list.isExpanded;
  const isExpanded = () => wrapper.vm.list.isExpanded;

  const findAddIssueButton = () => wrapper.find({ ref: 'newIssueBtn' });
  const findCaret = () => wrapper.find('.board-title-caret');

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
    it('does not collapse when clicking the header', () => {
      createComponent();

      expect(isCollapsed()).toBe(false);
      wrapper.find('[data-testid="board-list-header"]').trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(isCollapsed()).toBe(false);
      });
    });

    it('collapses expanded Column when clicking the collapse icon', () => {
      createComponent();

      expect(isExpanded()).toBe(true);
      findCaret().vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(isCollapsed()).toBe(true);
      });
    });

    it('expands collapsed Column when clicking the expand icon', () => {
      createComponent({ collapsed: true });

      expect(isCollapsed()).toBe(true);
      findCaret().vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(isCollapsed()).toBe(false);
      });
    });

    it("when logged in it calls list update and doesn't set localStorage", () => {
      jest.spyOn(List.prototype, 'update');

      createComponent({ withLocalStorage: false });

      findCaret().vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.list.update).toHaveBeenCalledTimes(1);
        expect(localStorage.getItem(`${wrapper.vm.uniqueKey}.expanded`)).toBe(null);
      });
    });

    it("when logged out it doesn't call list update and sets localStorage", () => {
      jest.spyOn(List.prototype, 'update');

      createComponent({ currentUserId: null });

      findCaret().vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.list.update).not.toHaveBeenCalled();
        expect(localStorage.getItem(`${wrapper.vm.uniqueKey}.expanded`)).toBe(String(isExpanded()));
      });
    });
  });
});
