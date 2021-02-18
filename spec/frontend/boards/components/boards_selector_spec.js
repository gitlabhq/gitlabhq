import { GlDropdown, GlLoadingIcon, GlDropdownSectionHeader } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { TEST_HOST } from 'spec/test_constants';
import BoardsSelector from '~/boards/components/boards_selector.vue';
import axios from '~/lib/utils/axios_utils';

const throttleDuration = 1;

function boardGenerator(n) {
  return new Array(n).fill().map((board, index) => {
    const id = `${index}`;
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
  let mock;
  const boards = boardGenerator(20);
  const recentBoards = boardGenerator(5);

  const fillSearchBox = (filterTerm) => {
    const searchBox = wrapper.find({ ref: 'searchBox' });
    const searchBoxInput = searchBox.find('input');
    searchBoxInput.setValue(filterTerm);
    searchBoxInput.trigger('input');
  };

  const getDropdownItems = () => wrapper.findAll('.js-dropdown-item');
  const getDropdownHeaders = () => wrapper.findAll(GlDropdownSectionHeader);
  const getLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findDropdown = () => wrapper.find(GlDropdown);

  beforeEach(() => {
    mock = new MockAdapter(axios);
    const $apollo = {
      queries: {
        boards: {
          loading: false,
        },
      },
    };

    allBoardsResponse = Promise.resolve({
      data: {
        group: {
          boards: {
            edges: boards.map((board) => ({ node: board })),
          },
        },
      },
    });
    recentBoardsResponse = Promise.resolve({
      data: recentBoards,
    });

    wrapper = mount(BoardsSelector, {
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
        boardBaseUrl: `${TEST_HOST}/board/base/url`,
        hasMissingBoards: false,
        canAdminBoard: true,
        multipleIssueBoardsAvailable: true,
        labelsPath: `${TEST_HOST}/labels/path`,
        labelsWebUrl: `${TEST_HOST}/labels`,
        projectId: 42,
        groupId: 19,
        scopedIssueBoardFeatureEnabled: true,
        weights: [],
      },
      mocks: { $apollo },
      attachTo: document.body,
      provide: {
        fullPath: '',
        recentBoardsEndpoint: `${TEST_HOST}/recent`,
      },
    });

    wrapper.vm.$apollo.addSmartQuery = jest.fn((_, options) => {
      wrapper.setData({
        [options.loadingKey]: true,
      });
    });

    mock.onGet(`${TEST_HOST}/recent`).replyOnce(200, recentBoards);

    // Emits gl-dropdown show event to simulate the dropdown is opened at initialization time
    findDropdown().vm.$emit('show');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mock.restore();
  });

  describe('loading', () => {
    // we are testing loading state, so don't resolve responses until after the tests
    afterEach(() => {
      return Promise.all([allBoardsResponse, recentBoardsResponse]).then(() => nextTick());
    });

    it('shows loading spinner', () => {
      expect(getDropdownHeaders()).toHaveLength(0);
      expect(getDropdownItems()).toHaveLength(0);
      expect(getLoadingIcon().exists()).toBe(true);
    });
  });

  describe('loaded', () => {
    beforeEach(async () => {
      await wrapper.setData({
        loadingBoards: false,
      });
      return Promise.all([allBoardsResponse, recentBoardsResponse]).then(() => nextTick());
    });

    it('hides loading spinner', async () => {
      await wrapper.vm.$nextTick();
      expect(getLoadingIcon().exists()).toBe(false);
    });

    describe('filtering', () => {
      beforeEach(() => {
        wrapper.setData({
          boards,
        });

        return nextTick();
      });

      it('shows all boards without filtering', () => {
        expect(getDropdownItems()).toHaveLength(boards.length + recentBoards.length);
      });

      it('shows only matching boards when filtering', () => {
        const filterTerm = 'board1';
        const expectedCount = boards.filter((board) => board.name.includes(filterTerm)).length;

        fillSearchBox(filterTerm);

        return nextTick().then(() => {
          expect(getDropdownItems()).toHaveLength(expectedCount);
        });
      });

      it('shows message if there are no matching boards', () => {
        fillSearchBox('does not exist');

        return nextTick().then(() => {
          expect(getDropdownItems()).toHaveLength(0);
          expect(wrapper.text().includes('No matching boards found')).toBe(true);
        });
      });
    });

    describe('recent boards section', () => {
      it('shows only when boards are greater than 10', () => {
        wrapper.setData({
          boards,
        });

        return nextTick().then(() => {
          expect(getDropdownHeaders()).toHaveLength(2);
        });
      });

      it('does not show when boards are less than 10', () => {
        wrapper.setData({
          boards: boards.slice(0, 5),
        });

        return nextTick().then(() => {
          expect(getDropdownHeaders()).toHaveLength(0);
        });
      });

      it('does not show when recentBoards api returns empty array', () => {
        wrapper.setData({
          recentBoards: [],
        });

        return nextTick().then(() => {
          expect(getDropdownHeaders()).toHaveLength(0);
        });
      });

      it('does not show when search is active', () => {
        fillSearchBox('Random string');

        return nextTick().then(() => {
          expect(getDropdownHeaders()).toHaveLength(0);
        });
      });
    });
  });
});
