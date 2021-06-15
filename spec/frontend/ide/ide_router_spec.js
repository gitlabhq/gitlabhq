import waitForPromises from 'helpers/wait_for_promises';
import { createRouter } from '~/ide/ide_router';
import { createStore } from '~/ide/stores';

describe('IDE router', () => {
  const PROJECT_NAMESPACE = 'my-group/sub-group';
  const PROJECT_NAME = 'my-project';
  const TEST_PATH = `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/merge_requests/2`;

  let store;
  let router;

  beforeEach(() => {
    window.history.replaceState({}, '', '/');
    store = createStore();
    router = createRouter(store);
    jest.spyOn(store, 'dispatch').mockReturnValue(new Promise(() => {}));
  });

  [
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/main/-/src/blob/`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/main/-/src/blob`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/blob/-/src/blob`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/main/-/src/tree/`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/weird:branch/name-123/-/src/tree/`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/main/-/src/blob`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/main/-/src/edit`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/main/-/src/merge_requests/2`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/blob/-/src/blob`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/edit/blob/-/src/blob`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/merge_requests/2`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/blob`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/edit`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}`,
  ].forEach((route) => {
    it(`finds project path when route is "${route}"`, () => {
      router.push(route);

      expect(store.dispatch).toHaveBeenCalledWith('getProjectData', {
        namespace: PROJECT_NAMESPACE,
        projectId: PROJECT_NAME,
      });
    });
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
