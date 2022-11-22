import UsersMockHelper from 'helpers/user_mock_data_helper';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import Mock from '../mock_data';

const ASSIGNEE = {
  id: 2,
  name: 'gitlab user 2',
  username: 'gitlab2',
  avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
};

const ANOTHER_ASSINEE = {
  id: 3,
  name: 'gitlab user 3',
  username: 'gitlab3',
  avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
};

describe('Sidebar store', () => {
  let testContext;

  beforeEach(() => {
    testContext = {};
  });

  beforeEach(() => {
    testContext.store = new SidebarStore({
      currentUser: {
        id: 1,
        name: 'Administrator',
        username: 'root',
        avatar_url:
          'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      },
      editable: true,
      rootPath: '/',
      endpoint: '/gitlab-org/gitlab-shell/issues/5.json',
    });
  });

  afterEach(() => {
    SidebarStore.singleton = null;
  });

  it('has default isFetching values', () => {
    expect(testContext.store.isFetching.assignees).toBe(true);
  });

  it('resets changing when resetChanging is called', () => {
    testContext.store.changing = true;

    testContext.store.resetChanging();

    expect(testContext.store.changing).toBe(false);
  });

  describe('when it adds a new assignee', () => {
    beforeEach(() => {
      testContext.store.addAssignee(ASSIGNEE);
    });

    it('adds a new assignee', () => {
      expect(testContext.store.assignees).toHaveLength(1);
    });

    it('sets changing to true', () => {
      expect(testContext.store.changing).toBe(true);
    });
  });

  describe('when it removes an assignee', () => {
    beforeEach(() => {
      testContext.store.removeAssignee(ASSIGNEE);
    });

    it('removes an assignee', () => {
      expect(testContext.store.assignees).toHaveLength(0);
    });

    it('sets changing to true', () => {
      expect(testContext.store.changing).toBe(true);
    });
  });

  it('finds an existent assignee', () => {
    let foundAssignee;

    testContext.store.addAssignee(ASSIGNEE);
    foundAssignee = testContext.store.findAssignee(ASSIGNEE);

    expect(foundAssignee).toBeDefined();
    expect(foundAssignee).toEqual(ASSIGNEE);
    foundAssignee = testContext.store.findAssignee(ANOTHER_ASSINEE);

    expect(foundAssignee).toBeUndefined();
  });

  it('removes all assignees', () => {
    testContext.store.removeAllAssignees();

    expect(testContext.store.assignees.length).toEqual(0);
    expect(testContext.store.changing).toBe(true);
  });

  it('set assigned data', () => {
    const users = {
      assignees: UsersMockHelper.createNumberRandomUsers(3),
    };

    testContext.store.setAssigneeData(users);

    expect(testContext.store.isFetching.assignees).toBe(false);
    expect(testContext.store.assignees.length).toEqual(3);
  });

  it('sets fetching state', () => {
    expect(testContext.store.isFetching.assignees).toEqual(true);

    testContext.store.setFetchingState('assignees', false);

    expect(testContext.store.isFetching.assignees).toEqual(false);
  });

  it('sets loading state', () => {
    testContext.store.setLoadingState('assignees', true);

    expect(testContext.store.isLoading.assignees).toEqual(true);
  });

  it('set time tracking data', () => {
    testContext.store.setTimeTrackingData(Mock.time);

    expect(testContext.store.timeEstimate).toEqual(Mock.time.time_estimate);
    expect(testContext.store.totalTimeSpent).toEqual(Mock.time.total_time_spent);
    expect(testContext.store.humanTimeEstimate).toEqual(Mock.time.human_time_estimate);
    expect(testContext.store.humanTotalTimeSpent).toEqual(Mock.time.human_total_time_spent);
  });

  it('set autocomplete projects', () => {
    const projects = [{ id: 0 }];
    testContext.store.setAutocompleteProjects(projects);

    expect(testContext.store.autocompleteProjects).toEqual(projects);
  });

  it('sets subscribed state', () => {
    expect(testContext.store.subscribed).toEqual(null);

    testContext.store.setSubscribedState(true);

    expect(testContext.store.subscribed).toEqual(true);
  });

  it('set move to project ID', () => {
    const projectId = 7;
    testContext.store.setMoveToProjectId(projectId);

    expect(testContext.store.moveToProjectId).toEqual(projectId);
  });
});
