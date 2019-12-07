import router from '~/ide/ide_router';
import store from '~/ide/stores';

describe('IDE router', () => {
  const PROJECT_NAMESPACE = 'my-group/sub-group';
  const PROJECT_NAME = 'my-project';

  afterEach(() => {
    router.push('/');
  });

  afterAll(() => {
    // VueRouter leaves this window.history at the "base" url. We need to clean this up.
    window.history.replaceState({}, '', '/');
  });

  [
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/master/-/src/blob/`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/master/-/src/blob`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/blob/-/src/blob`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/master/-/src/tree/`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/weird:branch/name-123/-/src/tree/`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/master/-/src/blob`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/master/-/src/edit`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/master/-/src/merge_requests/2`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/blob/blob/-/src/blob`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/edit/blob/-/src/blob`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/merge_requests/2`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/tree/blob`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}/edit`,
    `/project/${PROJECT_NAMESPACE}/${PROJECT_NAME}`,
  ].forEach(route => {
    it(`finds project path when route is "${route}"`, () => {
      jest.spyOn(store, 'dispatch').mockReturnValue(new Promise(() => {}));

      router.push(route);

      expect(store.dispatch).toHaveBeenCalledWith('getProjectData', {
        namespace: PROJECT_NAMESPACE,
        projectId: PROJECT_NAME,
      });
    });
  });
});
