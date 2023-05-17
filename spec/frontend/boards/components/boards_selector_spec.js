import { GlDropdown, GlLoadingIcon, GlDropdownSectionHeader } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'spec/test_constants';
import BoardsSelector from '~/boards/components/boards_selector.vue';
import groupBoardsQuery from '~/boards/graphql/group_boards.query.graphql';
import projectBoardsQuery from '~/boards/graphql/project_boards.query.graphql';
import groupRecentBoardsQuery from '~/boards/graphql/group_recent_boards.query.graphql';
import projectRecentBoardsQuery from '~/boards/graphql/project_recent_boards.query.graphql';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import {
  mockBoard,
  mockGroupAllBoardsResponse,
  mockProjectAllBoardsResponse,
  mockGroupRecentBoardsResponse,
  mockProjectRecentBoardsResponse,
  mockSmallProjectAllBoardsResponse,
  mockEmptyProjectRecentBoardsResponse,
  boards,
  recentIssueBoards,
} from '../mock_data';

const throttleDuration = 1;

Vue.use(VueApollo);
Vue.use(Vuex);

describe('BoardsSelector', () => {
  let wrapper;
  let fakeApollo;
  let store;

  const createStore = () => {
    store = new Vuex.Store({
      actions: {
        setError: jest.fn(),
        setBoardConfig: jest.fn(),
      },
      state: {
        board: mockBoard,
      },
    });
  };

  const fillSearchBox = (filterTerm) => {
    const searchBox = wrapper.findComponent({ ref: 'searchBox' });
    const searchBoxInput = searchBox.find('input');
    searchBoxInput.setValue(filterTerm);
    searchBoxInput.trigger('input');
  };

  const getDropdownItems = () => wrapper.findAllByTestId('dropdown-item');
  const getDropdownHeaders = () => wrapper.findAllComponents(GlDropdownSectionHeader);
  const getLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findDropdown = () => wrapper.findComponent(GlDropdown);

  const projectBoardsQueryHandlerSuccess = jest
    .fn()
    .mockResolvedValue(mockProjectAllBoardsResponse);
  const groupBoardsQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupAllBoardsResponse);

  const projectRecentBoardsQueryHandlerSuccess = jest
    .fn()
    .mockResolvedValue(mockProjectRecentBoardsResponse);
  const groupRecentBoardsQueryHandlerSuccess = jest
    .fn()
    .mockResolvedValue(mockGroupRecentBoardsResponse);

  const smallBoardsQueryHandlerSuccess = jest
    .fn()
    .mockResolvedValue(mockSmallProjectAllBoardsResponse);
  const emptyRecentBoardsQueryHandlerSuccess = jest
    .fn()
    .mockResolvedValue(mockEmptyProjectRecentBoardsResponse);

  const createComponent = ({
    projectBoardsQueryHandler = projectBoardsQueryHandlerSuccess,
    projectRecentBoardsQueryHandler = projectRecentBoardsQueryHandlerSuccess,
    isGroupBoard = false,
    isProjectBoard = false,
    provide = {},
  } = {}) => {
    fakeApollo = createMockApollo([
      [projectBoardsQuery, projectBoardsQueryHandler],
      [groupBoardsQuery, groupBoardsQueryHandlerSuccess],
      [projectRecentBoardsQuery, projectRecentBoardsQueryHandler],
      [groupRecentBoardsQuery, groupRecentBoardsQueryHandlerSuccess],
    ]);

    wrapper = mountExtended(BoardsSelector, {
      store,
      apolloProvider: fakeApollo,
      propsData: {
        throttleDuration,
      },
      attachTo: document.body,
      provide: {
        fullPath: '',
        boardBaseUrl: `${TEST_HOST}/board/base/url`,
        hasMissingBoards: false,
        canAdminBoard: true,
        multipleIssueBoardsAvailable: true,
        scopedIssueBoardFeatureEnabled: true,
        weights: [],
        boardType: isGroupBoard ? 'group' : 'project',
        isGroupBoard,
        isProjectBoard,
        isApolloBoard: false,
        ...provide,
      },
    });
  };

  afterEach(() => {
    fakeApollo = null;
  });

  describe('template', () => {
    beforeEach(() => {
      createStore();
      createComponent({ isProjectBoard: true });
    });

    describe('loading', () => {
      // we are testing loading state, so don't resolve responses until after the tests
      afterEach(async () => {
        await waitForPromises();
      });

      it('shows loading spinner', async () => {
        // Emits gl-dropdown show event to simulate the dropdown is opened at initialization time
        findDropdown().vm.$emit('show');
        await nextTick();

        expect(getLoadingIcon().exists()).toBe(true);
        expect(getDropdownHeaders()).toHaveLength(0);
        expect(getDropdownItems()).toHaveLength(0);
      });
    });

    describe('loaded', () => {
      beforeEach(async () => {
        // Wait for current board to be loaded
        await nextTick();

        // Emits gl-dropdown show event to simulate the dropdown is opened at initialization time
        findDropdown().vm.$emit('show');

        await nextTick();
      });

      it('fetches all issue boards', () => {
        expect(projectBoardsQueryHandlerSuccess).toHaveBeenCalled();
      });

      it('hides loading spinner', async () => {
        await nextTick();
        expect(getLoadingIcon().exists()).toBe(false);
      });

      describe('filtering', () => {
        beforeEach(async () => {
          await nextTick();
        });

        it('shows all boards without filtering', () => {
          expect(getDropdownItems()).toHaveLength(boards.length + recentIssueBoards.length);
        });

        it('shows only matching boards when filtering', async () => {
          const filterTerm = 'board1';
          const expectedCount = boards.filter((board) => board.node.name.includes(filterTerm))
            .length;

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
          await nextTick();
          expect(projectRecentBoardsQueryHandlerSuccess).toHaveBeenCalled();
          expect(getDropdownHeaders()).toHaveLength(2);
        });

        it('does not show when boards are less than 10', async () => {
          createComponent({ projectBoardsQueryHandler: smallBoardsQueryHandlerSuccess });

          await nextTick();
          expect(getDropdownHeaders()).toHaveLength(0);
        });

        it('does not show when recentIssueBoards api returns empty array', async () => {
          createComponent({
            projectRecentBoardsQueryHandler: emptyRecentBoardsQueryHandlerSuccess,
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

  describe('fetching all boards', () => {
    it.each`
      boardType            | queryHandler                        | notCalledHandler
      ${WORKSPACE_GROUP}   | ${groupBoardsQueryHandlerSuccess}   | ${projectBoardsQueryHandlerSuccess}
      ${WORKSPACE_PROJECT} | ${projectBoardsQueryHandlerSuccess} | ${groupBoardsQueryHandlerSuccess}
    `('fetches $boardType boards', async ({ boardType, queryHandler, notCalledHandler }) => {
      createStore();
      createComponent({
        isGroupBoard: boardType === WORKSPACE_GROUP,
        isProjectBoard: boardType === WORKSPACE_PROJECT,
      });

      await nextTick();

      // Emits gl-dropdown show event to simulate the dropdown is opened at initialization time
      findDropdown().vm.$emit('show');

      await nextTick();

      expect(queryHandler).toHaveBeenCalled();
      expect(notCalledHandler).not.toHaveBeenCalled();
    });
  });

  describe('dropdown visibility', () => {
    describe('when multipleIssueBoardsAvailable is enabled', () => {
      it('show dropdown', () => {
        createStore();
        createComponent({ provide: { multipleIssueBoardsAvailable: true } });
        expect(findDropdown().exists()).toBe(true);
      });
    });

    describe('when multipleIssueBoardsAvailable is disabled but it hasMissingBoards', () => {
      it('show dropdown', () => {
        createStore();
        createComponent({
          provide: { multipleIssueBoardsAvailable: false, hasMissingBoards: true },
        });
        expect(findDropdown().exists()).toBe(true);
      });
    });

    describe("when multipleIssueBoardsAvailable is disabled and it dosn't hasMissingBoards", () => {
      it('hide dropdown', () => {
        createStore();
        createComponent({
          provide: { multipleIssueBoardsAvailable: false, hasMissingBoards: false },
        });
        expect(findDropdown().exists()).toBe(false);
      });
    });
  });
});
