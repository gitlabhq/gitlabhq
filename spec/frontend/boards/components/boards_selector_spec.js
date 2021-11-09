import { GlDropdown, GlLoadingIcon, GlDropdownSectionHeader } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import { TEST_HOST } from 'spec/test_constants';
import BoardsSelector from '~/boards/components/boards_selector.vue';
import groupBoardQuery from '~/boards/graphql/group_board.query.graphql';
import projectBoardQuery from '~/boards/graphql/project_board.query.graphql';
import defaultStore from '~/boards/stores';
import axios from '~/lib/utils/axios_utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockGroupBoardResponse, mockProjectBoardResponse } from '../mock_data';

const throttleDuration = 1;

Vue.use(VueApollo);

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
  let fakeApollo;
  let store;
  const boards = boardGenerator(20);
  const recentBoards = boardGenerator(5);

  const createStore = ({ isGroupBoard = false, isProjectBoard = false } = {}) => {
    store = new Vuex.Store({
      ...defaultStore,
      actions: {
        setError: jest.fn(),
      },
      getters: {
        isGroupBoard: () => isGroupBoard,
        isProjectBoard: () => isProjectBoard,
      },
      state: {
        boardType: isGroupBoard ? 'group' : 'project',
      },
    });
  };

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

  const projectBoardQueryHandlerSuccess = jest.fn().mockResolvedValue(mockProjectBoardResponse);
  const groupBoardQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupBoardResponse);

  const createComponent = () => {
    fakeApollo = createMockApollo([
      [projectBoardQuery, projectBoardQueryHandlerSuccess],
      [groupBoardQuery, groupBoardQueryHandlerSuccess],
    ]);

    wrapper = mount(BoardsSelector, {
      store,
      apolloProvider: fakeApollo,
      propsData: {
        throttleDuration,
        boardBaseUrl: `${TEST_HOST}/board/base/url`,
        hasMissingBoards: false,
        canAdminBoard: true,
        multipleIssueBoardsAvailable: true,
        scopedIssueBoardFeatureEnabled: true,
        weights: [],
      },
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
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mock.restore();
  });

  describe('fetching all boards', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);

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

      createStore();
      createComponent();

      mock.onGet(`${TEST_HOST}/recent`).replyOnce(200, recentBoards);
    });

    describe('loading', () => {
      beforeEach(async () => {
        // Wait for current board to be loaded
        await nextTick();

        // Emits gl-dropdown show event to simulate the dropdown is opened at initialization time
        findDropdown().vm.$emit('show');
      });

      // we are testing loading state, so don't resolve responses until after the tests
      afterEach(async () => {
        await Promise.all([allBoardsResponse, recentBoardsResponse]);
        await nextTick();
      });

      it('shows loading spinner', () => {
        expect(getDropdownHeaders()).toHaveLength(0);
        expect(getDropdownItems()).toHaveLength(0);
        expect(getLoadingIcon().exists()).toBe(true);
      });
    });

    describe('loaded', () => {
      beforeEach(async () => {
        // Wait for current board to be loaded
        await nextTick();

        // Emits gl-dropdown show event to simulate the dropdown is opened at initialization time
        findDropdown().vm.$emit('show');

        await wrapper.setData({
          loadingBoards: false,
          loadingRecentBoards: false,
        });
        await Promise.all([allBoardsResponse, recentBoardsResponse]);
        await nextTick();
      });

      it('hides loading spinner', async () => {
        await nextTick();
        expect(getLoadingIcon().exists()).toBe(false);
      });

      describe('filtering', () => {
        beforeEach(async () => {
          wrapper.setData({
            boards,
          });

          await nextTick();
        });

        it('shows all boards without filtering', () => {
          expect(getDropdownItems()).toHaveLength(boards.length + recentBoards.length);
        });

        it('shows only matching boards when filtering', async () => {
          const filterTerm = 'board1';
          const expectedCount = boards.filter((board) => board.name.includes(filterTerm)).length;

          fillSearchBox(filterTerm);

          await nextTick();
          expect(getDropdownItems()).toHaveLength(expectedCount);
        });

        it('shows message if there are no matching boards', async () => {
          fillSearchBox('does not exist');

          await nextTick();
          expect(getDropdownItems()).toHaveLength(0);
          expect(wrapper.text().includes('No matching boards found')).toBe(true);
        });
      });

      describe('recent boards section', () => {
        it('shows only when boards are greater than 10', async () => {
          wrapper.setData({
            boards,
          });

          await nextTick();
          expect(getDropdownHeaders()).toHaveLength(2);
        });

        it('does not show when boards are less than 10', async () => {
          wrapper.setData({
            boards: boards.slice(0, 5),
          });

          await nextTick();
          expect(getDropdownHeaders()).toHaveLength(0);
        });

        it('does not show when recentBoards api returns empty array', async () => {
          wrapper.setData({
            recentBoards: [],
          });

          await nextTick();
          expect(getDropdownHeaders()).toHaveLength(0);
        });

        it('does not show when search is active', async () => {
          fillSearchBox('Random string');

          await nextTick();
          expect(getDropdownHeaders()).toHaveLength(0);
        });
      });
    });
  });

  describe('fetching current board', () => {
    it.each`
      boardType    | queryHandler                       | notCalledHandler
      ${'group'}   | ${groupBoardQueryHandlerSuccess}   | ${projectBoardQueryHandlerSuccess}
      ${'project'} | ${projectBoardQueryHandlerSuccess} | ${groupBoardQueryHandlerSuccess}
    `('fetches $boardType board', async ({ boardType, queryHandler, notCalledHandler }) => {
      createStore({
        isProjectBoard: boardType === 'project',
        isGroupBoard: boardType === 'group',
      });
      createComponent();

      await nextTick();

      expect(queryHandler).toHaveBeenCalled();
      expect(notCalledHandler).not.toHaveBeenCalled();
    });
  });
});
