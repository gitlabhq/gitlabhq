import SidebarStore from '~/sidebar/stores/sidebar_store';
import Mock from './mock_data';
import UsersMockHelper from '../helpers/user_mock_data_helper';

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

const PARTICIPANT = {
  id: 1,
  state: 'active',
  username: 'marcene',
  name: 'Allie Will',
  web_url: 'foo.com',
  avatar_url: 'gravatar.com/avatar/xxx',
};

const PARTICIPANT_LIST = [PARTICIPANT, { ...PARTICIPANT, id: 2 }, { ...PARTICIPANT, id: 3 }];

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

  it('adds a new assignee', () => {
    testContext.store.addAssignee(ASSIGNEE);

    expect(testContext.store.assignees.length).toEqual(1);
  });

  it('removes an assignee', () => {
    testContext.store.removeAssignee(ASSIGNEE);

    expect(testContext.store.assignees.length).toEqual(0);
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
  });

  it('sets participants data', () => {
    expect(testContext.store.participants.length).toEqual(0);

    testContext.store.setParticipantsData({
      participants: PARTICIPANT_LIST,
    });

    expect(testContext.store.isFetching.participants).toEqual(false);
    expect(testContext.store.participants.length).toEqual(PARTICIPANT_LIST.length);
  });

  it('sets subcriptions data', () => {
    expect(testContext.store.subscribed).toEqual(null);

    testContext.store.setSubscriptionsData({
      subscribed: true,
    });

    expect(testContext.store.isFetching.subscriptions).toEqual(false);
    expect(testContext.store.subscribed).toEqual(true);
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
    expect(testContext.store.isFetching.participants).toEqual(true);

    testContext.store.setFetchingState('participants', false);

    expect(testContext.store.isFetching.participants).toEqual(false);
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
