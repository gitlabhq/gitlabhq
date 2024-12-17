import VueRouter from 'vue-router';
import { describeSkipVue3, SkipReason } from 'helpers/vue3_conditional';
import IdeRouter from '~/ide/ide_router_extension';

jest.mock('vue-router');
const skipReason = new SkipReason({
  name: 'IDE overrides of VueRouter',
  reason: 'Legacy WebIDE is due for deletion',
  issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/508949',
});
describeSkipVue3(skipReason, () => {
  const paths = (branch) => [
    `${branch}`,
    `/${branch}`,
    `/${branch}/-/`,
    `/edit/${branch}`,
    `/edit/${branch}/-/`,
    `/blob/${branch}`,
    `/blob/${branch}/-/`,
    `/blob/${branch}/-/src/merge_requests/2`,
    `/blob/${branch}/-/src/blob/`,
    `/tree/${branch}/-/src/blob/`,
    `/tree/${branch}/-/src/tree/`,
  ];
  let router;

  beforeEach(() => {
    VueRouter.mockClear();
    router = new IdeRouter({
      mode: 'history',
    });
  });

  it.each`
    path               | expected
    ${'#-test'}        | ${'%23-test'}
    ${'#test'}         | ${'%23test'}
    ${'test#'}         | ${'test%23'}
    ${'test-#'}        | ${'test-%23'}
    ${'test-#-hash'}   | ${'test-%23-hash'}
    ${'test/hash#123'} | ${'test/hash%23123'}
  `('finds project path when route is $path', ({ path, expected }) => {
    paths(path).forEach((route) => {
      const expectedPath = route.replace(path, expected);

      router.push(route);
      expect(VueRouter.prototype.push).toHaveBeenCalledWith(expectedPath, undefined, undefined);

      router.resolve(route);
      expect(VueRouter.prototype.resolve).toHaveBeenCalledWith(expectedPath, undefined, undefined);
    });
  });
});
