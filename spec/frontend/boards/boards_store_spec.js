import { TEST_HOST } from 'helpers/test_constants';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import boardsStore from '~/boards/stores/boards_store';

describe('boardsStore', () => {
  const dummyResponse = "without type checking this doesn't matter";
  const boardId = 'dummy-board-id';
  const endpoints = {
    boardsEndpoint: `${TEST_HOST}/boards`,
    listsEndpoint: `${TEST_HOST}/lists`,
    bulkUpdatePath: `${TEST_HOST}/bulk/update`,
    recentBoardsEndpoint: `${TEST_HOST}/recent/boards`,
  };

  let axiosMock;

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    boardsStore.setEndpoints({
      ...endpoints,
      boardId,
    });
  });

  describe('all', () => {
    it('makes a request to fetch lists', () => {
      axiosMock.onGet(endpoints.listsEndpoint).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.all()).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onGet(endpoints.listsEndpoint).replyOnce(500);

      return expect(boardsStore.all()).rejects.toThrow();
    });
  });

  describe('generateDefaultLists', () => {
    const listsEndpointGenerate = `${endpoints.listsEndpoint}/generate.json`;

    it('makes a request to generate default lists', () => {
      axiosMock.onPost(listsEndpointGenerate).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.generateDefaultLists()).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onPost(listsEndpointGenerate).replyOnce(500);

      return expect(boardsStore.generateDefaultLists()).rejects.toThrow();
    });
  });

  describe('createList', () => {
    const entityType = 'moorhen';
    const entityId = 'quack';
    const expectedRequest = expect.objectContaining({
      data: JSON.stringify({ list: { [entityType]: entityId } }),
    });

    let requestSpy;

    beforeEach(() => {
      requestSpy = jest.fn();
      axiosMock.onPost(endpoints.listsEndpoint).replyOnce(config => requestSpy(config));
    });

    it('makes a request to create a list', () => {
      requestSpy.mockReturnValue([200, dummyResponse]);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.createList(entityId, entityType))
        .resolves.toEqual(expectedResponse)
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });

    it('fails for error response', () => {
      requestSpy.mockReturnValue([500]);

      return expect(boardsStore.createList(entityId, entityType))
        .rejects.toThrow()
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });
  });

  describe('updateList', () => {
    const id = 'David Webb';
    const position = 'unknown';
    const collapsed = false;
    const expectedRequest = expect.objectContaining({
      data: JSON.stringify({ list: { position, collapsed } }),
    });

    let requestSpy;

    beforeEach(() => {
      requestSpy = jest.fn();
      axiosMock.onPut(`${endpoints.listsEndpoint}/${id}`).replyOnce(config => requestSpy(config));
    });

    it('makes a request to update a list position', () => {
      requestSpy.mockReturnValue([200, dummyResponse]);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.updateList(id, position, collapsed))
        .resolves.toEqual(expectedResponse)
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });

    it('fails for error response', () => {
      requestSpy.mockReturnValue([500]);

      return expect(boardsStore.updateList(id, position, collapsed))
        .rejects.toThrow()
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });
  });

  describe('destroyList', () => {
    const id = '-42';

    let requestSpy;

    beforeEach(() => {
      requestSpy = jest.fn();
      axiosMock
        .onDelete(`${endpoints.listsEndpoint}/${id}`)
        .replyOnce(config => requestSpy(config));
    });

    it('makes a request to delete a list', () => {
      requestSpy.mockReturnValue([200, dummyResponse]);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.destroyList(id))
        .resolves.toEqual(expectedResponse)
        .then(() => {
          expect(requestSpy).toHaveBeenCalled();
        });
    });

    it('fails for error response', () => {
      requestSpy.mockReturnValue([500]);

      return expect(boardsStore.destroyList(id))
        .rejects.toThrow()
        .then(() => {
          expect(requestSpy).toHaveBeenCalled();
        });
    });
  });

  describe('getIssuesForList', () => {
    const id = 'TOO-MUCH';
    const url = `${endpoints.listsEndpoint}/${id}/issues?id=${id}`;

    it('makes a request to fetch list issues', () => {
      axiosMock.onGet(url).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.getIssuesForList(id)).resolves.toEqual(expectedResponse);
    });

    it('makes a request to fetch list issues with filter', () => {
      const filter = { algal: 'scrubber' };
      axiosMock.onGet(`${url}&algal=scrubber`).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.getIssuesForList(id, filter)).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onGet(url).replyOnce(500);

      return expect(boardsStore.getIssuesForList(id)).rejects.toThrow();
    });
  });

  describe('moveIssue', () => {
    const urlRoot = 'potato';
    const id = 'over 9000';
    const fromListId = 'left';
    const toListId = 'right';
    const moveBeforeId = 'up';
    const moveAfterId = 'down';
    const expectedRequest = expect.objectContaining({
      data: JSON.stringify({
        from_list_id: fromListId,
        to_list_id: toListId,
        move_before_id: moveBeforeId,
        move_after_id: moveAfterId,
      }),
    });

    let requestSpy;

    beforeAll(() => {
      global.gon.relative_url_root = urlRoot;
    });

    afterAll(() => {
      delete global.gon.relative_url_root;
    });

    beforeEach(() => {
      requestSpy = jest.fn();
      axiosMock
        .onPut(`${urlRoot}/-/boards/${boardId}/issues/${id}`)
        .replyOnce(config => requestSpy(config));
    });

    it('makes a request to move an issue between lists', () => {
      requestSpy.mockReturnValue([200, dummyResponse]);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.moveIssue(id, fromListId, toListId, moveBeforeId, moveAfterId))
        .resolves.toEqual(expectedResponse)
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });

    it('fails for error response', () => {
      requestSpy.mockReturnValue([500]);

      return expect(boardsStore.moveIssue(id, fromListId, toListId, moveBeforeId, moveAfterId))
        .rejects.toThrow()
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });
  });

  describe('newIssue', () => {
    const id = 'not-creative';
    const issue = { some: 'issue data' };
    const url = `${endpoints.listsEndpoint}/${id}/issues`;
    const expectedRequest = expect.objectContaining({
      data: JSON.stringify({
        issue,
      }),
    });

    let requestSpy;

    beforeEach(() => {
      requestSpy = jest.fn();
      axiosMock.onPost(url).replyOnce(config => requestSpy(config));
    });

    it('makes a request to create a new issue', () => {
      requestSpy.mockReturnValue([200, dummyResponse]);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.newIssue(id, issue))
        .resolves.toEqual(expectedResponse)
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });

    it('fails for error response', () => {
      requestSpy.mockReturnValue([500]);

      return expect(boardsStore.newIssue(id, issue))
        .rejects.toThrow()
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });
  });

  describe('getBacklog', () => {
    const urlRoot = 'deep';
    const url = `${urlRoot}/-/boards/${boardId}/issues.json?not=relevant`;
    const requestParams = {
      not: 'relevant',
    };

    beforeAll(() => {
      global.gon.relative_url_root = urlRoot;
    });

    afterAll(() => {
      delete global.gon.relative_url_root;
    });

    it('makes a request to fetch backlog', () => {
      axiosMock.onGet(url).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.getBacklog(requestParams)).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onGet(url).replyOnce(500);

      return expect(boardsStore.getBacklog(requestParams)).rejects.toThrow();
    });
  });

  describe('bulkUpdate', () => {
    const issueIds = [1, 2, 3];
    const extraData = { moar: 'data' };
    const expectedRequest = expect.objectContaining({
      data: JSON.stringify({
        update: {
          ...extraData,
          issuable_ids: '1,2,3',
        },
      }),
    });

    let requestSpy;

    beforeEach(() => {
      requestSpy = jest.fn();
      axiosMock.onPost(endpoints.bulkUpdatePath).replyOnce(config => requestSpy(config));
    });

    it('makes a request to create a list', () => {
      requestSpy.mockReturnValue([200, dummyResponse]);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.bulkUpdate(issueIds, extraData))
        .resolves.toEqual(expectedResponse)
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });

    it('fails for error response', () => {
      requestSpy.mockReturnValue([500]);

      return expect(boardsStore.bulkUpdate(issueIds, extraData))
        .rejects.toThrow()
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });
  });

  describe('getIssueInfo', () => {
    const dummyEndpoint = `${TEST_HOST}/some/where`;

    it('makes a request to the given endpoint', () => {
      axiosMock.onGet(dummyEndpoint).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.getIssueInfo(dummyEndpoint)).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onGet(dummyEndpoint).replyOnce(500);

      return expect(boardsStore.getIssueInfo(dummyEndpoint)).rejects.toThrow();
    });
  });

  describe('toggleIssueSubscription', () => {
    const dummyEndpoint = `${TEST_HOST}/some/where`;

    it('makes a request to the given endpoint', () => {
      axiosMock.onPost(dummyEndpoint).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.toggleIssueSubscription(dummyEndpoint)).resolves.toEqual(
        expectedResponse,
      );
    });

    it('fails for error response', () => {
      axiosMock.onPost(dummyEndpoint).replyOnce(500);

      return expect(boardsStore.toggleIssueSubscription(dummyEndpoint)).rejects.toThrow();
    });
  });

  describe('allBoards', () => {
    const url = `${endpoints.boardsEndpoint}.json`;

    it('makes a request to fetch all boards', () => {
      axiosMock.onGet(url).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.allBoards()).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onGet(url).replyOnce(500);

      return expect(boardsStore.allBoards()).rejects.toThrow();
    });
  });

  describe('recentBoards', () => {
    const url = `${endpoints.recentBoardsEndpoint}.json`;

    it('makes a request to fetch all boards', () => {
      axiosMock.onGet(url).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.recentBoards()).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onGet(url).replyOnce(500);

      return expect(boardsStore.recentBoards()).rejects.toThrow();
    });
  });

  describe('createBoard', () => {
    const labelIds = ['first label', 'second label'];
    const assigneeId = 'as sign ee';
    const milestoneId = 'vegetable soup';
    const board = {
      labels: labelIds.map(id => ({ id })),
      assignee: { id: assigneeId },
      milestone: { id: milestoneId },
    };

    describe('for existing board', () => {
      const id = 'skate-board';
      const url = `${endpoints.boardsEndpoint}/${id}.json`;
      const expectedRequest = expect.objectContaining({
        data: JSON.stringify({
          board: {
            ...board,
            id,
            label_ids: labelIds,
            assignee_id: assigneeId,
            milestone_id: milestoneId,
          },
        }),
      });

      let requestSpy;

      beforeEach(() => {
        requestSpy = jest.fn();
        axiosMock.onPut(url).replyOnce(config => requestSpy(config));
      });

      it('makes a request to update the board', () => {
        requestSpy.mockReturnValue([200, dummyResponse]);
        const expectedResponse = expect.objectContaining({ data: dummyResponse });

        return expect(
          boardsStore.createBoard({
            ...board,
            id,
          }),
        )
          .resolves.toEqual(expectedResponse)
          .then(() => {
            expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
          });
      });

      it('fails for error response', () => {
        requestSpy.mockReturnValue([500]);

        return expect(
          boardsStore.createBoard({
            ...board,
            id,
          }),
        )
          .rejects.toThrow()
          .then(() => {
            expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
          });
      });
    });

    describe('for new board', () => {
      const url = `${endpoints.boardsEndpoint}.json`;
      const expectedRequest = expect.objectContaining({
        data: JSON.stringify({
          board: {
            ...board,
            label_ids: labelIds,
            assignee_id: assigneeId,
            milestone_id: milestoneId,
          },
        }),
      });

      let requestSpy;

      beforeEach(() => {
        requestSpy = jest.fn();
        axiosMock.onPost(url).replyOnce(config => requestSpy(config));
      });

      it('makes a request to create a new board', () => {
        requestSpy.mockReturnValue([200, dummyResponse]);
        const expectedResponse = expect.objectContaining({ data: dummyResponse });

        return expect(boardsStore.createBoard(board))
          .resolves.toEqual(expectedResponse)
          .then(() => {
            expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
          });
      });

      it('fails for error response', () => {
        requestSpy.mockReturnValue([500]);

        return expect(boardsStore.createBoard(board))
          .rejects.toThrow()
          .then(() => {
            expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
          });
      });
    });
  });

  describe('deleteBoard', () => {
    const id = 'capsized';
    const url = `${endpoints.boardsEndpoint}/${id}.json`;

    it('makes a request to delete a boards', () => {
      axiosMock.onDelete(url).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(boardsStore.deleteBoard({ id })).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onDelete(url).replyOnce(500);

      return expect(boardsStore.deleteBoard({ id })).rejects.toThrow();
    });
  });
});
