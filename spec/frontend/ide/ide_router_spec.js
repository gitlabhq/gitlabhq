import waitForPromises from 'helpers/wait_for_promises';
import { stubPerformanceWebAPI } from 'helpers/performance';
import { describeSkipVue3, SkipReason } from 'helpers/vue3_conditional';
import { createRouter } from '~/ide/ide_router';
import { createStore } from '~/ide/stores';

const skipReason = new SkipReason({
  name: 'IDE router',
  reason: 'Legacy WebIDE is due for deletion',
  issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/508949',
});
describeSkipVue3(skipReason, () => {
  const PROJECT_NAMESPACE = 'my-group/sub-group';
  const PROJECT_NAME = 'my-project';
  const TEST_PATH = `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/merge_requests/2`;
  const DEFAULT_BRANCH = 'default-main';

  let store;
  let router;

  beforeEach(() => {
    stubPerformanceWebAPI();

    window.history.replaceState({}, '', '/');
    store = createStore();
    router = createRouter(store, DEFAULT_BRANCH);
    jest.spyOn(store, 'dispatch').mockReturnValue(new Promise(() => {}));
  });

  it.each`
    route                                                                                     | expectedBranchId           | expectedBasePath
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/main/-/src/blob/`}                  | ${'main'}                  | ${'src/blob/'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/main/-/src/blob`}                   | ${'main'}                  | ${'src/blob'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/blob/-/src/blob`}                   | ${'blob'}                  | ${'src/blob'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/main/-/src/tree/`}                  | ${'main'}                  | ${'src/tree/'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/weird:branch/name-123/-/src/tree/`} | ${'weird:branch/name-123'} | ${'src/tree/'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/main/-/src/blob`}                   | ${'main'}                  | ${'src/blob'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/main/-/src/edit`}                   | ${'main'}                  | ${'src/edit'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/main/-/src/merge_requests/2`}       | ${'main'}                  | ${'src/merge_requests/2'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/blob/-/src/blob`}                   | ${'blob'}                  | ${'src/blob'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/edit/blob/-/src/blob`}                   | ${'blob'}                  | ${'src/blob'}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/blob`}                              | ${'blob'}                  | ${''}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/edit`}                                   | ${DEFAULT_BRANCH}          | ${''}
    ${`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}`}                                        | ${DEFAULT_BRANCH}          | ${''}
  `('correctly opens Web IDE for $route', ({ route, expectedBranchId, expectedBasePath } = {}) => {
    router.push(route);

    expect(store.dispatch).toHaveBeenCalledWith('openBranch', {
      projectId: `${PROJECT_NAMESPACE}/${PROJECT_NAME}`,
      branchId: expectedBranchId,
      basePath: expectedBasePath,
    });
  });

  it('correctly opens an MR', () => {
    const expectedId = '2';

    router.push(`/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/merge_requests/${expectedId}`);

    expect(store.dispatch).toHaveBeenCalledWith('openMergeRequest', {
      projectId: `${PROJECT_NAMESPACE}/${PROJECT_NAME}`,
      mergeRequestId: expectedId,
      targetProjectId: undefined,
    });
    expect(store.dispatch).not.toHaveBeenCalledWith('openBranch');
  });

  it('keeps router in sync when store changes', async () => {
    expect(router.currentRoute.fullPath).toBe('/');

    store.state.router.fullPath = TEST_PATH;

    await waitForPromises();

    expect(router.currentRoute.fullPath).toBe(TEST_PATH);
  });

  it('keeps store in sync when router changes', () => {
    expect(store.dispatch).not.toHaveBeenCalled();

    router.push(TEST_PATH);

    expect(store.dispatch).toHaveBeenCalledWith('router/push', TEST_PATH, { root: true });
  });
});
