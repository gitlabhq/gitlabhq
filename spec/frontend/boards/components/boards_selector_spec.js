import Vue from 'vue';
import { mount } from '@vue/test-utils';
import { GlDropdown } from '@gitlab/ui';
import { TEST_HOST } from 'spec/test_constants';
import BoardsSelector from '~/boards/components/boards_selector.vue';
import boardsStore from '~/boards/stores/boards_store';

const throttleDuration = 1;

function boardGenerator(n) {
  return new Array(n).fill().map((board, id) => {
    const name = `board${id}`;

    return {
      id,
      name,
    };
  });
}

describe('BoardsSelector', () => {
  let wrapper;
  let allBoardsResponse;
  let recentBoardsResponse;
  const boards = boardGenerator(20);
  const recentBoards = boardGenerator(5);

  const fillSearchBox = filterTerm => {
    const searchBox = wrapper.find({ ref: 'searchBox' });
    const searchBoxInput = searchBox.find('input');
    searchBoxInput.setValue(filterTerm);
    searchBoxInput.trigger('input');
  };

  const getDropdownItems = () => wrapper.findAll('.js-dropdown-item');
  const getDropdownHeaders = () => wrapper.findAll('.dropdown-bold-header');

  beforeEach(() => {
    boardsStore.setEndpoints({
      boardsEndpoint: '',
      recentBoardsEndpoint: '',
      listsEndpoint: '',
      bulkUpdatePath: '',
      boardId: '',
    });

    allBoardsResponse = Promise.resolve({
      data: boards,
    });
    recentBoardsResponse = Promise.resolve({
      data: recentBoards,
    });

    boardsStore.allBoards = jest.fn(() => allBoardsResponse);
    boardsStore.recentBoards = jest.fn(() => recentBoardsResponse);

    const Component = Vue.extend(BoardsSelector);
    wrapper = mount(Component, {
      propsData: {
        throttleDuration,
        currentBoard: {
          id: 1,
          name: 'Development',
          milestone_id: null,
          weight: null,
          assignee_id: null,
          labels: [],
        },
        milestonePath: `${TEST_HOST}/milestone/path`,
        boardBaseUrl: `${TEST_HOST}/board/base/url`,
        hasMissingBoards: false,
        canAdminBoard: true,
        multipleIssueBoardsAvailable: true,
        labelsPath: `${TEST_HOST}/labels/path`,
        projectId: 42,
        groupId: 19,
        scopedIssueBoardFeatureEnabled: true,
        weights: [],
      },
      attachToDocument: true,
    });

    // Emits gl-dropdown show event to simulate the dropdown is opened at initialization time
    wrapper.find(GlDropdown).vm.$emit('show');

    return Promise.all([allBoardsResponse, recentBoardsResponse]).then(() => Vue.nextTick());
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('filtering', () => {
    it('shows all boards without filtering', () => {
      expect(getDropdownItems().length).toBe(boards.length + recentBoards.length);
    });

    it('shows only matching boards when filtering', () => {
      const filterTerm = 'board1';
      const expectedCount = boards.filter(board => board.name.includes(filterTerm)).length;

      fillSearchBox(filterTerm);

      return Vue.nextTick().then(() => {
        expect(getDropdownItems().length).toBe(expectedCount);
      });
    });

    it('shows message if there are no matching boards', () => {
      fillSearchBox('does not exist');

      return Vue.nextTick().then(() => {
        expect(getDropdownItems().length).toBe(0);
        expect(wrapper.text().includes('No matching boards found')).toBe(true);
      });
    });
  });

  describe('recent boards section', () => {
    it('shows only when boards are greater than 10', () => {
      const expectedCount = 2; // Recent + All

      expect(getDropdownHeaders().length).toBe(expectedCount);
    });

    it('does not show when boards are less than 10', () => {
      wrapper.setData({
        boards: boards.slice(0, 5),
      });

      return Vue.nextTick().then(() => {
        expect(getDropdownHeaders().length).toBe(0);
      });
    });

    it('does not show when recentBoards api returns empty array', () => {
      wrapper.setData({
        recentBoards: [],
      });

      return Vue.nextTick().then(() => {
        expect(getDropdownHeaders().length).toBe(0);
      });
    });

    it('does not show when search is active', () => {
      fillSearchBox('Random string');

      return Vue.nextTick().then(() => {
        expect(getDropdownHeaders().length).toBe(0);
      });
    });
  });
});
