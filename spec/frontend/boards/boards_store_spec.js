import AxiosMockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import boardsStore from '~/boards/stores/boards_store';
import eventHub from '~/boards/eventhub';
import { listObj, listObjDuplicate } from './mock_data';

import ListIssue from '~/boards/models/issue';
import '~/boards/models/list';

jest.mock('js-cookie');

const createTestIssue = () => ({
  title: 'Testing',
  id: 1,
  iid: 1,
  confidential: false,
  labels: [],
  assignees: [],
});

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

  afterEach(() => {
    axiosMock.restore();
  });

  const setupDefaultResponses = () => {
    axiosMock
      .onGet(`${endpoints.listsEndpoint}/${listObj.id}/issues?id=${listObj.id}&page=1`)
      .reply(200, { issues: [createTestIssue()] });
    axiosMock.onPost(endpoints.listsEndpoint).reply(200, listObj);
    axiosMock.onPut();
  };

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

  describe('when created', () => {
    beforeEach(() => {
      setupDefaultResponses();

      jest.spyOn(boardsStore, 'moveIssue').mockReturnValue(Promise.resolve());
      jest.spyOn(boardsStore, 'moveMultipleIssues').mockReturnValue(Promise.resolve());

      boardsStore.create();
    });

    it('starts with a blank state', () => {
      expect(boardsStore.state.lists.length).toBe(0);
    });

    describe('addList', () => {
      it('sorts by position', () => {
        boardsStore.addList({ position: 2 });
        boardsStore.addList({ position: 1 });

        expect(boardsStore.state.lists.map(({ position }) => position)).toEqual([1, 2]);
      });
    });

    describe('toggleFilter', () => {
      const dummyFilter = 'x=42';
      let updateTokensSpy;

      beforeEach(() => {
        updateTokensSpy = jest.fn();
        eventHub.$once('updateTokens', updateTokensSpy);

        // prevent using window.history
        jest.spyOn(boardsStore, 'updateFiltersUrl').mockReturnValue();
      });

      it('adds the filter if it is not present', () => {
        boardsStore.filter.path = 'something';

        boardsStore.toggleFilter(dummyFilter);

        expect(boardsStore.filter.path).toEqual(`something&${dummyFilter}`);
        expect(updateTokensSpy).toHaveBeenCalled();
        expect(boardsStore.updateFiltersUrl).toHaveBeenCalled();
      });

      it('removes the filter if it is present', () => {
        boardsStore.filter.path = `something&${dummyFilter}`;

        boardsStore.toggleFilter(dummyFilter);

        expect(boardsStore.filter.path).toEqual('something');
        expect(updateTokensSpy).toHaveBeenCalled();
        expect(boardsStore.updateFiltersUrl).toHaveBeenCalled();
      });
    });

    describe('lists', () => {
      it('creates new list without persisting to DB', () => {
        expect(boardsStore.state.lists.length).toBe(0);

        boardsStore.addList(listObj);

        expect(boardsStore.state.lists.length).toBe(1);
      });

      it('finds list by ID', () => {
        boardsStore.addList(listObj);
        const list = boardsStore.findList('id', listObj.id);

        expect(list.id).toBe(listObj.id);
      });

      it('finds list by type', () => {
        boardsStore.addList(listObj);
        const list = boardsStore.findList('type', 'label');

        expect(list).toBeDefined();
      });

      it('finds list by label ID', () => {
        boardsStore.addList(listObj);
        const list = boardsStore.findListByLabelId(listObj.label.id);

        expect(list.id).toBe(listObj.id);
      });

      it('gets issue when new list added', () => {
        boardsStore.addList(listObj);
        const list = boardsStore.findList('id', listObj.id);

        expect(boardsStore.state.lists.length).toBe(1);

        return axios.waitForAll().then(() => {
          expect(list.issues.length).toBe(1);
          expect(list.issues[0].id).toBe(1);
        });
      });

      it('persists new list', () => {
        boardsStore.new({
          title: 'Test',
          list_type: 'label',
          label: {
            id: 1,
            title: 'Testing',
            color: 'red',
            description: 'testing;',
          },
        });

        expect(boardsStore.state.lists.length).toBe(1);

        return axios.waitForAll().then(() => {
          const list = boardsStore.findList('id', listObj.id);

          expect(list).toEqual(
            expect.objectContaining({
              id: listObj.id,
              position: 0,
            }),
          );
        });
      });

      it('check for blank state adding', () => {
        expect(boardsStore.shouldAddBlankState()).toBe(true);
      });

      it('check for blank state not adding', () => {
        boardsStore.addList(listObj);

        expect(boardsStore.shouldAddBlankState()).toBe(false);
      });

      it('check for blank state adding when closed list exist', () => {
        boardsStore.addList({
          list_type: 'closed',
        });

        expect(boardsStore.shouldAddBlankState()).toBe(true);
      });

      it('adds the blank state', () => {
        boardsStore.addBlankState();

        const list = boardsStore.findList('type', 'blank', 'blank');

        expect(list).toBeDefined();
      });

      it('removes list from state', () => {
        boardsStore.addList(listObj);

        expect(boardsStore.state.lists.length).toBe(1);

        boardsStore.removeList(listObj.id, 'label');

        expect(boardsStore.state.lists.length).toBe(0);
      });

      it('moves the position of lists', () => {
        const listOne = boardsStore.addList(listObj);
        boardsStore.addList(listObjDuplicate);

        expect(boardsStore.state.lists.length).toBe(2);

        boardsStore.moveList(listOne, [listObjDuplicate.id, listObj.id]);

        expect(listOne.position).toBe(1);
      });

      it('moves an issue from one list to another', () => {
        const listOne = boardsStore.addList(listObj);
        const listTwo = boardsStore.addList(listObjDuplicate);

        expect(boardsStore.state.lists.length).toBe(2);

        return axios.waitForAll().then(() => {
          expect(listOne.issues.length).toBe(1);
          expect(listTwo.issues.length).toBe(1);

          boardsStore.moveIssueToList(listOne, listTwo, listOne.findIssue(1));

          expect(listOne.issues.length).toBe(0);
          expect(listTwo.issues.length).toBe(1);
        });
      });

      it('moves an issue from backlog to a list', () => {
        const backlog = boardsStore.addList({
          ...listObj,
          list_type: 'backlog',
        });
        const listTwo = boardsStore.addList(listObjDuplicate);

        expect(boardsStore.state.lists.length).toBe(2);

        return axios.waitForAll().then(() => {
          expect(backlog.issues.length).toBe(1);
          expect(listTwo.issues.length).toBe(1);

          boardsStore.moveIssueToList(backlog, listTwo, backlog.findIssue(1));

          expect(backlog.issues.length).toBe(0);
          expect(listTwo.issues.length).toBe(1);
        });
      });

      it('moves issue to top of another list', () => {
        const listOne = boardsStore.addList(listObj);
        const listTwo = boardsStore.addList(listObjDuplicate);

        expect(boardsStore.state.lists.length).toBe(2);

        return axios.waitForAll().then(() => {
          listOne.issues[0].id = 2;

          expect(listOne.issues.length).toBe(1);
          expect(listTwo.issues.length).toBe(1);

          boardsStore.moveIssueToList(listOne, listTwo, listOne.findIssue(2), 0);

          expect(listOne.issues.length).toBe(0);
          expect(listTwo.issues.length).toBe(2);
          expect(listTwo.issues[0].id).toBe(2);
          expect(boardsStore.moveIssue).toHaveBeenCalledWith(2, listOne.id, listTwo.id, null, 1);
        });
      });

      it('moves issue to bottom of another list', () => {
        const listOne = boardsStore.addList(listObj);
        const listTwo = boardsStore.addList(listObjDuplicate);

        expect(boardsStore.state.lists.length).toBe(2);

        return axios.waitForAll().then(() => {
          listOne.issues[0].id = 2;

          expect(listOne.issues.length).toBe(1);
          expect(listTwo.issues.length).toBe(1);

          boardsStore.moveIssueToList(listOne, listTwo, listOne.findIssue(2), 1);

          expect(listOne.issues.length).toBe(0);
          expect(listTwo.issues.length).toBe(2);
          expect(listTwo.issues[1].id).toBe(2);
          expect(boardsStore.moveIssue).toHaveBeenCalledWith(2, listOne.id, listTwo.id, 1, null);
        });
      });

      it('moves issue in list', () => {
        const issue = new ListIssue({
          title: 'Testing',
          id: 2,
          iid: 2,
          confidential: false,
          labels: [],
          assignees: [],
        });
        const list = boardsStore.addList(listObj);

        return axios.waitForAll().then(() => {
          list.addIssue(issue);

          expect(list.issues.length).toBe(2);

          boardsStore.moveIssueInList(list, issue, 0, 1, [1, 2]);

          expect(list.issues[0].id).toBe(2);
          expect(boardsStore.moveIssue).toHaveBeenCalledWith(2, null, null, 1, null);
        });
      });
    });

    describe('setListDetail', () => {
      it('sets the list detail', () => {
        boardsStore.detail.list = 'not a list';

        const dummyValue = 'new list';
        boardsStore.setListDetail(dummyValue);

        expect(boardsStore.detail.list).toEqual(dummyValue);
      });
    });

    describe('clearDetailIssue', () => {
      it('resets issue details', () => {
        boardsStore.detail.issue = 'something';

        boardsStore.clearDetailIssue();

        expect(boardsStore.detail.issue).toEqual({});
      });
    });

    describe('setIssueDetail', () => {
      it('sets issue details', () => {
        boardsStore.detail.issue = 'some details';

        const dummyValue = 'new details';
        boardsStore.setIssueDetail(dummyValue);

        expect(boardsStore.detail.issue).toEqual(dummyValue);
      });
    });

    describe('startMoving', () => {
      it('stores list and issue', () => {
        const dummyIssue = 'some issue';
        const dummyList = 'some list';

        boardsStore.startMoving(dummyList, dummyIssue);

        expect(boardsStore.moving.issue).toEqual(dummyIssue);
        expect(boardsStore.moving.list).toEqual(dummyList);
      });
    });

    describe('setTimeTrackingLimitToHours', () => {
      it('sets the timeTracking.LimitToHours option', () => {
        boardsStore.timeTracking.limitToHours = false;

        boardsStore.setTimeTrackingLimitToHours('true');

        expect(boardsStore.timeTracking.limitToHours).toEqual(true);
      });
    });

    describe('setCurrentBoard', () => {
      const dummyBoard = 'hoverboard';

      it('sets the current board', () => {
        const { state } = boardsStore;
        state.currentBoard = null;

        boardsStore.setCurrentBoard(dummyBoard);

        expect(state.currentBoard).toEqual(dummyBoard);
      });
    });

    describe('toggleMultiSelect', () => {
      let basicIssueObj;

      beforeAll(() => {
        basicIssueObj = { id: 987654 };
      });

      afterEach(() => {
        boardsStore.clearMultiSelect();
      });

      it('adds issue when not present', () => {
        boardsStore.toggleMultiSelect(basicIssueObj);

        const selectedIds = boardsStore.multiSelect.list.map(({ id }) => id);

        expect(selectedIds.includes(basicIssueObj.id)).toEqual(true);
      });

      it('removes issue when issue is present', () => {
        boardsStore.toggleMultiSelect(basicIssueObj);
        let selectedIds = boardsStore.multiSelect.list.map(({ id }) => id);

        expect(selectedIds.includes(basicIssueObj.id)).toEqual(true);

        boardsStore.toggleMultiSelect(basicIssueObj);
        selectedIds = boardsStore.multiSelect.list.map(({ id }) => id);

        expect(selectedIds.includes(basicIssueObj.id)).toEqual(false);
      });
    });

    describe('clearMultiSelect', () => {
      it('clears all the multi selected issues', () => {
        const issue1 = { id: 12345 };
        const issue2 = { id: 12346 };

        boardsStore.toggleMultiSelect(issue1);
        boardsStore.toggleMultiSelect(issue2);

        expect(boardsStore.multiSelect.list.length).toEqual(2);

        boardsStore.clearMultiSelect();

        expect(boardsStore.multiSelect.list.length).toEqual(0);
      });
    });

    describe('moveMultipleIssuesToList', () => {
      it('move issues on the new index', () => {
        const listOne = boardsStore.addList(listObj);
        const listTwo = boardsStore.addList(listObjDuplicate);

        expect(boardsStore.state.lists.length).toBe(2);

        return axios.waitForAll().then(() => {
          expect(listOne.issues.length).toBe(1);
          expect(listTwo.issues.length).toBe(1);

          boardsStore.moveMultipleIssuesToList({
            listFrom: listOne,
            listTo: listTwo,
            issues: listOne.issues,
            newIndex: 0,
          });

          expect(listTwo.issues.length).toBe(1);
        });
      });
    });

    describe('moveMultipleIssuesInList', () => {
      it('moves multiple issues in list', () => {
        const issueObj = {
          title: 'Issue #1',
          id: 12345,
          iid: 2,
          confidential: false,
          labels: [],
          assignees: [],
        };
        const issue1 = new ListIssue(issueObj);
        const issue2 = new ListIssue({
          ...issueObj,
          title: 'Issue #2',
          id: 12346,
        });

        const list = boardsStore.addList(listObj);

        return axios.waitForAll().then(() => {
          list.addIssue(issue1);
          list.addIssue(issue2);

          expect(list.issues.length).toBe(3);
          expect(list.issues[0].id).not.toBe(issue2.id);

          boardsStore.moveMultipleIssuesInList({
            list,
            issues: [issue1, issue2],
            oldIndicies: [0],
            newIndex: 1,
            idArray: [1, 12345, 12346],
          });

          expect(list.issues[0].id).toBe(issue1.id);

          expect(boardsStore.moveMultipleIssues).toHaveBeenCalledWith({
            ids: [issue1.id, issue2.id],
            fromListId: null,
            toListId: null,
            moveBeforeId: 1,
            moveAfterId: null,
          });
        });
      });
    });
  });
});
