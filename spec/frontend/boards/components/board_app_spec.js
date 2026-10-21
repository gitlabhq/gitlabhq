import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import { createControlledMockApollo } from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BoardApp from '~/boards/components/board_app.vue';
import BoardTopBar from '~/boards/components/board_top_bar.vue';
import BoardContent from '~/boards/components/board_content.vue';
import activeBoardItemQuery from 'ee_else_ce/boards/graphql/client/active_board_item.query.graphql';
import boardListsQuery from 'ee_else_ce/boards/graphql/board_lists.query.graphql';
import listCountQuery from 'ee_else_ce/boards/graphql/board_lists_deferred.query.graphql';
import listIssuesQuery from '~/boards/graphql/lists_issues.query.graphql';
import * as cacheUpdates from '~/boards/graphql/cache_updates';
import {
  rawIssue,
  boardListsQueryResponse,
  boardListQueryResponse,
  mockGroupIssuesResponse,
} from '../mock_data';

describe('BoardApp', () => {
  let wrapper;
  let mockApollo;
  let resolveQuery;
  let rejectQuery;

  const findBoardTopBar = () => wrapper.findComponent(BoardTopBar);
  const findBoardContent = () => wrapper.findComponent(BoardContent);

  const errorMessage = 'Failed to fetch lists';
  const boardListQueryHandler = jest.fn().mockResolvedValue(boardListsQueryResponse);
  const listIssuesQueryHandler = jest.fn().mockResolvedValue(mockGroupIssuesResponse());
  const listCountQueryHandler = jest
    .fn()
    .mockResolvedValue(boardListQueryResponse({ listId: 'gid://gitlab/List/1' }));

  Vue.use(VueApollo);

  const createComponent = ({
    issue = rawIssue,
    handler = boardListQueryHandler,
    isIssueBoard = true,
  } = {}) => {
    ({
      apolloProvider: mockApollo,
      resolveQuery,
      rejectQuery,
    } = createControlledMockApollo([
      [boardListsQuery, handler],
      [listIssuesQuery, listIssuesQueryHandler],
      [listCountQuery, listCountQueryHandler],
    ]));
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
        hasCustomFieldsFeature: false,
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
    expect(classes).toContain('@lg/panel:gl-w-[calc(100%-480px)]');
    expect(classes).toContain('@xl/panel:gl-w-[calc(100%-768px)]');
    expect(classes).toContain('min-[1440px]:gl-w-[calc(100%-912px)]');
  });

  it('should not have dynamic width classes class when no card is selected', async () => {
    createComponent({ issue: {} });
    await nextTick();

    const classes = findBoardContent().classes();
    expect(classes).not.toContain('@lg/panel:gl-w-[calc(100%-480px)]');
    expect(classes).not.toContain('@xl/panel:gl-w-[calc(100%-768px)]');
    expect(classes).not.toContain('min-[1440px]:gl-w-[calc(100%-912px)]');
  });

  it('refetches lists when top bar emits update-board event', async () => {
    createComponent();
    await resolveQuery(boardListsQuery);
    findBoardTopBar().vm.$emit('update-board');

    expect(boardListQueryHandler).toHaveBeenCalled();
  });

  it('sets error on fetch lists failure', async () => {
    createComponent();

    await rejectQuery(boardListsQuery, new Error(errorMessage));

    expect(cacheUpdates.setError).toHaveBeenCalled();
  });

  describe('when the top bar submits filters', () => {
    const watchFirstListQueries = async () => {
      const client = mockApollo.clients.defaultClient;
      const listId = 'gid://gitlab/List/1';

      client
        .watchQuery({
          query: listIssuesQuery,
          variables: {
            fullPath: 'gitlab-org',
            boardId: 'gid://gitlab/Board/1',
            id: listId,
            filters: {},
            isGroup: true,
            first: 10,
          },
        })
        .subscribe(() => {});
      client.watchQuery({ query: listCountQuery, variables: { id: listId } }).subscribe(() => {});

      await resolveQuery(listIssuesQuery);
      await resolveQuery(listCountQuery);
    };

    beforeEach(async () => {
      createComponent();
      await resolveQuery(boardListsQuery);
      await watchFirstListQueries();

      boardListQueryHandler.mockClear();
      listIssuesQueryHandler.mockClear();
      listCountQueryHandler.mockClear();
    });

    it('refetches the lists, their issues and their counts when the filters are unchanged', async () => {
      findBoardTopBar().vm.$emit('submit-filters', {});
      await waitForPromises();

      expect(boardListQueryHandler).toHaveBeenCalledTimes(1);
      expect(listIssuesQueryHandler).toHaveBeenCalledTimes(1);
      expect(listCountQueryHandler).toHaveBeenCalledTimes(1);
    });

    it('fetches the lists once with the new filters when the filters changed', async () => {
      findBoardTopBar().vm.$emit('submit-filters', { milestoneTitle: 'v1' });
      await waitForPromises();

      expect(boardListQueryHandler).toHaveBeenCalledTimes(1);
      expect(boardListQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({ filters: expect.objectContaining({ milestoneTitle: 'v1' }) }),
      );
      expect(listIssuesQueryHandler).not.toHaveBeenCalled();
      expect(listCountQueryHandler).not.toHaveBeenCalled();
    });

    it('does not refetch when set-filters carries unchanged filters', async () => {
      findBoardTopBar().vm.$emit('set-filters', {});
      await waitForPromises();

      expect(boardListQueryHandler).not.toHaveBeenCalled();
      expect(listIssuesQueryHandler).not.toHaveBeenCalled();
      expect(listCountQueryHandler).not.toHaveBeenCalled();
    });
  });
});
