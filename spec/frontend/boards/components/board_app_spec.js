import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BoardApp from '~/boards/components/board_app.vue';
import BoardTopBar from '~/boards/components/board_top_bar.vue';
import BoardContent from '~/boards/components/board_content.vue';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import boardListsQuery from 'ee_else_ce/boards/graphql/board_lists.query.graphql';
import * as cacheUpdates from '~/boards/graphql/cache_updates';
import { rawIssue, boardListsQueryResponse } from '../mock_data';

describe('BoardApp', () => {
  let wrapper;
  let mockApollo;

  const findBoardTopBar = () => wrapper.findComponent(BoardTopBar);
  const findBoardContent = () => wrapper.findComponent(BoardContent);

  const errorMessage = 'Failed to fetch lists';
  const boardListQueryHandler = jest.fn().mockResolvedValue(boardListsQueryResponse);
  const boardListQueryHandlerFailure = jest.fn().mockRejectedValue(new Error(errorMessage));

  Vue.use(VueApollo);

  const createComponent = ({
    issue = rawIssue,
    handler = boardListQueryHandler,
    workItemDrawerEnabled = true,
    isIssueBoard = true,
  } = {}) => {
    mockApollo = createMockApollo([[boardListsQuery, handler]]);
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: activeBoardItemQuery,
      data: {
        activeBoardItem: { ...issue, listId: 'gid://gitlab/List/1' },
      },
    });

    wrapper = shallowMount(BoardApp, {
      apolloProvider: mockApollo,
      provide: {
        fullPath: 'gitlab-org',
        initialBoardId: 'gid://gitlab/Board/1',
        initialFilterParams: {},
        issuableType: isIssueBoard ? 'issue' : 'epic',
        boardType: isIssueBoard ? 'project' : 'group',
        isIssueBoard,
        isGroupBoard: false,
        glFeatures: {
          issuesListDrawer: workItemDrawerEnabled,
          epicsListDrawer: !workItemDrawerEnabled,
        },
      },
    });
  };

  beforeEach(async () => {
    cacheUpdates.setError = jest.fn();

    createComponent();
    await nextTick();
  });

  it('fetches lists', () => {
    expect(boardListQueryHandler).toHaveBeenCalled();
  });

  it('should have dynamic width classes when a card is selected', async () => {
    findBoardContent().vm.$emit('drawer-opened');
    await nextTick();
    const classes = findBoardContent().classes();
    expect(classes).toContain('lg:gl-w-[calc(100%-480px)]');
    expect(classes).toContain('xl:gl-w-[calc(100%-768px)]');
    expect(classes).toContain('min-[1440px]:gl-w-[calc(100%-912px)]');
  });

  it('should not have dynamic width classes class when no card is selected', async () => {
    createComponent({ issue: {} });
    await nextTick();

    const classes = findBoardContent().classes();
    expect(classes).not.toContain('lg:gl-w-[calc(100%-480px)]');
    expect(classes).not.toContain('xl:gl-w-[calc(100%-768px)]');
    expect(classes).not.toContain('min-[1440px]:gl-w-[calc(100%-912px)]');
  });

  it('refetches lists when top bar emits updateBoard event', async () => {
    createComponent();
    await waitForPromises();
    findBoardTopBar().vm.$emit('updateBoard');

    expect(boardListQueryHandler).toHaveBeenCalled();
  });

  it('sets error on fetch lists failure', async () => {
    createComponent({ handler: boardListQueryHandlerFailure });

    await waitForPromises();

    expect(cacheUpdates.setError).toHaveBeenCalled();
  });

  describe('when on issue board', () => {
    describe('when `issuesListDrawer` feature is disabled', () => {
      beforeEach(() => {
        createComponent({ workItemDrawerEnabled: false });
      });

      it('passes `useWorkItemDrawer` as false', () => {
        expect(findBoardContent().props('useWorkItemDrawer')).toBe(false);
      });
    });

    describe('when `issuesListDrawer` feature is enabled', () => {
      beforeEach(() => {
        createComponent({ workItemDrawerEnabled: true });
      });

      it('passes `useWorkItemDrawer` as true', () => {
        expect(findBoardContent().props('useWorkItemDrawer')).toBe(true);
      });
    });
  });
});
