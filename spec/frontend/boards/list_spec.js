/* global List */
/* global ListAssignee */
/* global ListIssue */
/* global ListLabel */
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import '~/boards/models/label';
import '~/boards/models/assignee';
import '~/boards/models/issue';
import '~/boards/models/list';
import { ListType } from '~/boards/constants';
import boardsStore from '~/boards/stores/boards_store';
import axios from '~/lib/utils/axios_utils';
import { listObj, listObjDuplicate, boardsMockInterceptor } from './mock_data';

describe('List model', () => {
  let list;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onAny().reply(boardsMockInterceptor);
    boardsStore.create();
    boardsStore.setEndpoints({
      listsEndpoint: '/test/-/boards/1/lists',
    });

    list = new List(listObj);
    return waitForPromises();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('list type', () => {
    const notExpandableList = ['blank'];

    const table = Object.keys(ListType).map((k) => {
      const value = ListType[k];
      return [value, !notExpandableList.includes(value)];
    });
    it.each(table)(`when list_type is %s boards isExpandable is %p`, (type, result) => {
      expect(new List({ id: 1, list_type: type }).isExpandable).toBe(result);
    });
  });

  it('gets issues when created', () => {
    expect(list.issues.length).toBe(1);
  });

  it('saves list and returns ID', () => {
    list = new List({
      title: 'test',
      label: {
        id: 1,
        title: 'test',
        color: '#ff0000',
        text_color: 'white',
      },
    });
    return list.save().then(() => {
      expect(list.id).toBe(listObj.id);
      expect(list.type).toBe('label');
      expect(list.position).toBe(0);
      expect(list.label).toEqual(listObj.label);
    });
  });

  it('destroys the list', () => {
    boardsStore.addList(listObj);
    list = boardsStore.findList('id', listObj.id);

    expect(boardsStore.state.lists.length).toBe(1);
    list.destroy();

    return waitForPromises().then(() => {
      expect(boardsStore.state.lists.length).toBe(0);
    });
  });

  it('gets issue from list', () => {
    const issue = list.findIssue(1);

    expect(issue).toBeDefined();
  });

  it('removes issue', () => {
    const issue = list.findIssue(1);

    expect(list.issues.length).toBe(1);
    list.removeIssue(issue);

    expect(list.issues.length).toBe(0);
  });

  it('sends service request to update issue label', () => {
    const listDup = new List(listObjDuplicate);
    const issue = new ListIssue({
      title: 'Testing',
      id: 1,
      iid: 1,
      confidential: false,
      labels: [list.label, listDup.label],
      assignees: [],
    });

    list.issues.push(issue);
    listDup.issues.push(issue);

    jest.spyOn(boardsStore, 'moveIssue');

    listDup.updateIssueLabel(issue, list);

    expect(boardsStore.moveIssue).toHaveBeenCalledWith(
      issue.id,
      list.id,
      listDup.id,
      undefined,
      undefined,
    );
  });

  describe('page number', () => {
    beforeEach(() => {
      jest.spyOn(list, 'getIssues').mockImplementation(() => {});
      list.issues = [];
    });

    it('increase page number if current issue count is more than the page size', () => {
      for (let i = 0; i < 30; i += 1) {
        list.issues.push(
          new ListIssue({
            title: 'Testing',
            id: i,
            iid: i,
            confidential: false,
            labels: [list.label],
            assignees: [],
          }),
        );
      }
      list.issuesSize = 50;

      expect(list.issues.length).toBe(30);

      list.nextPage();

      expect(list.page).toBe(2);
      expect(list.getIssues).toHaveBeenCalled();
    });

    it('does not increase page number if issue count is less than the page size', () => {
      list.issues.push(
        new ListIssue({
          title: 'Testing',
          id: 1,
          confidential: false,
          labels: [list.label],
          assignees: [],
        }),
      );
      list.issuesSize = 2;

      list.nextPage();

      expect(list.page).toBe(1);
      expect(list.getIssues).toHaveBeenCalled();
    });
  });

  describe('newIssue', () => {
    beforeEach(() => {
      jest.spyOn(boardsStore, 'newIssue').mockReturnValue(
        Promise.resolve({
          data: {
            id: 42,
            subscribed: false,
            assignable_labels_endpoint: '/issue/42/labels',
            toggle_subscription_endpoint: '/issue/42/subscriptions',
            issue_sidebar_endpoint: '/issue/42/sidebar_info',
          },
        }),
      );
      list.issues = [];
    });

    it('adds new issue to top of list', (done) => {
      const user = new ListAssignee({
        id: 1,
        name: 'testing 123',
        username: 'test',
        avatar: 'test_image',
      });

      list.issues.push(
        new ListIssue({
          title: 'Testing',
          id: 1,
          confidential: false,
          labels: [new ListLabel(list.label)],
          assignees: [],
        }),
      );
      const dummyIssue = new ListIssue({
        title: 'new issue',
        id: 2,
        confidential: false,
        labels: [new ListLabel(list.label)],
        assignees: [user],
        subscribed: false,
      });

      list
        .newIssue(dummyIssue)
        .then(() => {
          expect(list.issues.length).toBe(2);
          expect(list.issues[0]).toBe(dummyIssue);
          expect(list.issues[0].subscribed).toBe(false);
          expect(list.issues[0].assignableLabelsEndpoint).toBe('/issue/42/labels');
          expect(list.issues[0].toggleSubscriptionEndpoint).toBe('/issue/42/subscriptions');
          expect(list.issues[0].sidebarInfoEndpoint).toBe('/issue/42/sidebar_info');
          expect(list.issues[0].labels).toBe(dummyIssue.labels);
          expect(list.issues[0].assignees).toBe(dummyIssue.assignees);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
