import BoardService from '~/boards/services/board_service';
import { TEST_HOST } from 'helpers/test_constants';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';

describe('BoardService', () => {
  const dummyResponse = "without type checking this doesn't matter";
  const boardId = 'dummy-board-id';
  const endpoints = {
    boardsEndpoint: `${TEST_HOST}/boards`,
    listsEndpoint: `${TEST_HOST}/lists`,
    bulkUpdatePath: `${TEST_HOST}/bulk/update`,
    recentBoardsEndpoint: `${TEST_HOST}/recent/boards`,
  };

  let service;
  let axiosMock;

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    service = new BoardService({
      ...endpoints,
      boardId,
    });
  });

  describe('all', () => {
    it('makes a request to fetch lists', () => {
      axiosMock.onGet(endpoints.listsEndpoint).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(service.all()).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onGet(endpoints.listsEndpoint).replyOnce(500);

      return expect(service.all()).rejects.toThrow();
    });
  });

  describe('generateDefaultLists', () => {
    const listsEndpointGenerate = `${endpoints.listsEndpoint}/generate.json`;

    it('makes a request to generate default lists', () => {
      axiosMock.onPost(listsEndpointGenerate).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(service.generateDefaultLists()).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onPost(listsEndpointGenerate).replyOnce(500);

      return expect(service.generateDefaultLists()).rejects.toThrow();
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

      return expect(service.createList(entityId, entityType))
        .resolves.toEqual(expectedResponse)
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });

    it('fails for error response', () => {
      requestSpy.mockReturnValue([500]);

      return expect(service.createList(entityId, entityType))
        .rejects.toThrow()
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });
  });

  describe('updateList', () => {
    const id = 'David Webb';
    const position = 'unknown';
    const expectedRequest = expect.objectContaining({
      data: JSON.stringify({ list: { position } }),
    });

    let requestSpy;

    beforeEach(() => {
      requestSpy = jest.fn();
      axiosMock.onPut(`${endpoints.listsEndpoint}/${id}`).replyOnce(config => requestSpy(config));
    });

    it('makes a request to update a list position', () => {
      requestSpy.mockReturnValue([200, dummyResponse]);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(service.updateList(id, position))
        .resolves.toEqual(expectedResponse)
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });

    it('fails for error response', () => {
      requestSpy.mockReturnValue([500]);

      return expect(service.updateList(id, position))
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

      return expect(service.destroyList(id))
        .resolves.toEqual(expectedResponse)
        .then(() => {
          expect(requestSpy).toHaveBeenCalled();
        });
    });

    it('fails for error response', () => {
      requestSpy.mockReturnValue([500]);

      return expect(service.destroyList(id))
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

      return expect(service.getIssuesForList(id)).resolves.toEqual(expectedResponse);
    });

    it('makes a request to fetch list issues with filter', () => {
      const filter = { algal: 'scrubber' };
      axiosMock.onGet(`${url}&algal=scrubber`).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(service.getIssuesForList(id, filter)).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onGet(url).replyOnce(500);

      return expect(service.getIssuesForList(id)).rejects.toThrow();
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

      return expect(service.moveIssue(id, fromListId, toListId, moveBeforeId, moveAfterId))
        .resolves.toEqual(expectedResponse)
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });

    it('fails for error response', () => {
      requestSpy.mockReturnValue([500]);

      return expect(service.moveIssue(id, fromListId, toListId, moveBeforeId, moveAfterId))
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

      return expect(service.newIssue(id, issue))
        .resolves.toEqual(expectedResponse)
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });

    it('fails for error response', () => {
      requestSpy.mockReturnValue([500]);

      return expect(service.newIssue(id, issue))
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

      return expect(service.getBacklog(requestParams)).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onGet(url).replyOnce(500);

      return expect(service.getBacklog(requestParams)).rejects.toThrow();
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

      return expect(service.bulkUpdate(issueIds, extraData))
        .resolves.toEqual(expectedResponse)
        .then(() => {
          expect(requestSpy).toHaveBeenCalledWith(expectedRequest);
        });
    });

    it('fails for error response', () => {
      requestSpy.mockReturnValue([500]);

      return expect(service.bulkUpdate(issueIds, extraData))
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

      return expect(BoardService.getIssueInfo(dummyEndpoint)).resolves.toEqual(expectedResponse);
    });

    it('fails for error response', () => {
      axiosMock.onGet(dummyEndpoint).replyOnce(500);

      return expect(BoardService.getIssueInfo(dummyEndpoint)).rejects.toThrow();
    });
  });

  describe('toggleIssueSubscription', () => {
    const dummyEndpoint = `${TEST_HOST}/some/where`;

    it('makes a request to the given endpoint', () => {
      axiosMock.onPost(dummyEndpoint).replyOnce(200, dummyResponse);
      const expectedResponse = expect.objectContaining({ data: dummyResponse });

      return expect(BoardService.toggleIssueSubscription(dummyEndpoint)).resolves.toEqual(
        expectedResponse,
      );
    });

    it('fails for error response', () => {
      axiosMock.onPost(dummyEndpoint).replyOnce(500);

      return expect(BoardService.toggleIssueSubscription(dummyEndpoint)).rejects.toThrow();
    });
  });
});
