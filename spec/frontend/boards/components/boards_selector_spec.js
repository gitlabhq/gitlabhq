import { GlCollapsibleListbox, GlButton } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_HOST } from 'spec/test_constants';
import { formType } from '~/boards/constants';
import BoardsSelector from '~/boards/components/boards_selector.vue';
import BoardForm from '~/boards/components/board_form.vue';
import groupBoardsQuery from '~/boards/graphql/group_boards.query.graphql';
import projectBoardsQuery from '~/boards/graphql/project_boards.query.graphql';
import groupRecentBoardsQuery from '~/boards/graphql/group_recent_boards.query.graphql';
import projectRecentBoardsQuery from '~/boards/graphql/project_recent_boards.query.graphql';
import * as cacheUpdates from '~/boards/graphql/cache_updates';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
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

describe('BoardsSelector', () => {
  let wrapper;
  let fakeApollo;

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findBoardForm = () => wrapper.findComponent(BoardForm);

  const fillSearchBox = async (filterTerm) => {
    await findDropdown().vm.$emit('search', filterTerm);
  };

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

  const boardsHandlerFailure = jest.fn().mockRejectedValue(new Error('error'));

  const createComponent = ({
    projectBoardsQueryHandler = projectBoardsQueryHandlerSuccess,
    projectRecentBoardsQueryHandler = projectRecentBoardsQueryHandlerSuccess,
    groupBoardsQueryHandler = groupBoardsQueryHandlerSuccess,
    isGroupBoard = false,
    isProjectBoard = false,
    provide = {},
    props = {},
  } = {}) => {
    fakeApollo = createMockApollo([
      [projectBoardsQuery, projectBoardsQueryHandler],
      [groupBoardsQuery, groupBoardsQueryHandler],
      [projectRecentBoardsQuery, projectRecentBoardsQueryHandler],
      [groupRecentBoardsQuery, groupRecentBoardsQueryHandlerSuccess],
    ]);

    wrapper = shallowMountExtended(BoardsSelector, {
      apolloProvider: fakeApollo,
      propsData: {
        throttleDuration,
        board: mockBoard,
        ...props,
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
        isIssueBoard: true,
        ...provide,
      },
      stubs: { BoardForm },
    });
  };

  beforeEach(() => {
    cacheUpdates.setError = jest.fn();
  });

  afterEach(() => {
    fakeApollo = null;
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent({ isProjectBoard: true });
    });

    describe('loading', () => {
      // we are testing loading state, so don't resolve responses until after the tests
      afterEach(async () => {
        await waitForPromises();
      });

      it('displays loading state of dropdown while current board is being fetched', () => {
        createComponent({
          props: { isCurrentBoardLoading: true },
        });
        expect(findDropdown().props('loading')).toBe(true);
        expect(findDropdown().props('toggleText')).toBe('Select board');
      });

      it('shows loading spinner', async () => {
        createComponent({
          props: {
            isCurrentBoardLoading: true,
          },
        });
        // Emits gl-dropdown show event to simulate the dropdown is opened at initialization time
        findDropdown().vm.$emit('shown');
        await nextTick();

        expect(findDropdown().props('loading')).toBe(true);
      });
    });

    describe('loaded', () => {
      beforeEach(async () => {
        // Wait for current board to be loaded
        await nextTick();

        // Emits gl-dropdown show event to simulate the dropdown is opened at initialization time
        findDropdown().vm.$emit('shown');

        await nextTick();
      });

      it('fetches all issue boards', () => {
        expect(projectBoardsQueryHandlerSuccess).toHaveBeenCalled();
      });

      it('hides loading spinner', () => {
        expect(findDropdown().props('loading')).toBe(false);
      });

      describe('filtering', () => {
        beforeEach(async () => {
          await nextTick();
        });

        it('shows all boards without filtering', () => {
          expect(findDropdown().props('items')[0].text).toBe('Recent');
          expect(findDropdown().props('items')[0].options).toHaveLength(recentIssueBoards.length);
          expect(findDropdown().props('items')[1].text).toBe('All');
          expect(findDropdown().props('items')[1].options).toHaveLength(
            boards.length - recentIssueBoards.length,
          );
        });

        it('shows only matching boards when filtering', async () => {
          const filterTerm = 'board1';
          const expectedCount = boards.filter((board) => board.name.includes(filterTerm)).length;

          await fillSearchBox(filterTerm);
          expect(findDropdown().props('items')).toHaveLength(expectedCount);
        });

        it('shows message if there are no matching boards', async () => {
          await fillSearchBox('does not exist');

          expect(findDropdown().props('noResultsText')).toBe('No matching boards found');
        });
      });

      describe('recent boards section', () => {
        it('shows only when boards are greater than 10', async () => {
          await nextTick();
          expect(projectRecentBoardsQueryHandlerSuccess).toHaveBeenCalled();

          expect(findDropdown().props('items')).toHaveLength(2);
          expect(findDropdown().props('items')[0].text).toBe('Recent');
          expect(findDropdown().props('items')[1].text).toBe('All');
        });

        it('does not show when boards are less than 10', async () => {
          createComponent({ projectBoardsQueryHandler: smallBoardsQueryHandlerSuccess });

          await nextTick();

          expect(findDropdown().props('items')).toHaveLength(0);
        });

        it('does not show when recentIssueBoards api returns empty array', async () => {
          createComponent({
            projectRecentBoardsQueryHandler: emptyRecentBoardsQueryHandlerSuccess,
          });

          await nextTick();
          expect(findDropdown().props('items')).toHaveLength(0);
        });

        it('does not show when search is active', async () => {
          fillSearchBox('Random string');

          await nextTick();
          expect(findDropdown().props('items')).toHaveLength(0);
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
      createComponent({
        isGroupBoard: boardType === WORKSPACE_GROUP,
        isProjectBoard: boardType === WORKSPACE_PROJECT,
      });

      await nextTick();

      // Emits gl-dropdown show event to simulate the dropdown is opened at initialization time
      findDropdown().vm.$emit('shown');

      await nextTick();

      expect(queryHandler).toHaveBeenCalled();
      expect(notCalledHandler).not.toHaveBeenCalled();
    });

    it.each`
      boardType
      ${WORKSPACE_GROUP}
      ${WORKSPACE_PROJECT}
    `('sets error when fetching $boardType boards fails', async ({ boardType }) => {
      createComponent({
        isGroupBoard: boardType === WORKSPACE_GROUP,
        isProjectBoard: boardType === WORKSPACE_PROJECT,
        projectBoardsQueryHandler: boardsHandlerFailure,
        groupBoardsQueryHandler: boardsHandlerFailure,
      });

      await nextTick();

      // Emits gl-dropdown show event to simulate the dropdown is opened at initialization time
      findDropdown().vm.$emit('shown');

      await waitForPromises();

      expect(cacheUpdates.setError).toHaveBeenCalled();
    });
  });

  describe('dropdown visibility', () => {
    describe('when multipleIssueBoardsAvailable is enabled', () => {
      it('show dropdown', () => {
        createComponent({ provide: { multipleIssueBoardsAvailable: true } });
        expect(findDropdown().exists()).toBe(true);
        expect(findDropdown().props('toggleText')).toBe('Select board');
      });
    });

    describe('when multipleIssueBoardsAvailable is disabled but it hasMissingBoards', () => {
      it('show dropdown', () => {
        createComponent({
          provide: { multipleIssueBoardsAvailable: false, hasMissingBoards: true },
        });
        expect(findDropdown().exists()).toBe(true);
        expect(findDropdown().props('toggleText')).toBe('Select board');
      });
    });

    describe("when multipleIssueBoardsAvailable is disabled and it dosn't hasMissingBoards", () => {
      it('hide dropdown', () => {
        createComponent({
          provide: { multipleIssueBoardsAvailable: false, hasMissingBoards: false },
        });
        expect(findDropdown().exists()).toBe(false);
      });
    });
  });

  describe('board form', () => {
    it('does not show board form by default', () => {
      createComponent();
      expect(findBoardForm().exists()).toBe(false);
    });

    it('shows board form when boardModalForm prop is set', () => {
      createComponent({
        props: {
          boardModalForm: formType.new,
        },
      });
      expect(findBoardForm().exists()).toBe(true);
    });

    it('emits showBoardModal when BoardForm emits cancel', async () => {
      createComponent({
        props: {
          boardModalForm: formType.new,
        },
      });

      findBoardForm().vm.$emit('cancel');
      await nextTick();

      expect(wrapper.emitted('showBoardModal')).toEqual([['']]);
    });

    it('emits showBoardModal with new when clicking on create board button', async () => {
      createComponent({ isProjectBoard: true });

      findDropdown().vm.$emit('shown');
      await waitForPromises();

      wrapper.findComponent(GlButton).vm.$emit('click');
      expect(wrapper.emitted('showBoardModal')).toEqual([[formType.new]]);
    });

    it('emits showBoardModal when BoardForm emits showBoardModal', () => {
      createComponent({
        isProjectBoard: true,
        props: {
          boardModalForm: formType.edit,
        },
      });

      findBoardForm().vm.$emit('showBoardModal', formType.delete);
      expect(wrapper.emitted('showBoardModal')).toEqual([[formType.delete]]);
    });
  });
});
