import { createRouter } from '~/projects/commits/router';

describe('Commits router spec', () => {
  const basePath = 'gitlab-org/gitlab/commits';
  const escapedRef = 'main';

  describe('route matching', () => {
    it.each`
      path                                    | expectedParams
      ${'/main/'}                             | ${{ path: '' }}
      ${'/main/README.md'}                    | ${{ path: ['README.md'] }}
      ${'/main/app/assets'}                   | ${{ path: ['app', 'assets'] }}
      ${'/main/app/assets/javascripts'}       | ${{ path: ['app', 'assets', 'javascripts'] }}
      ${'/main/src/file%20with%20spaces.txt'} | ${{ path: ['src', 'file with spaces.txt'] }}
      ${'/main/src/file.vue'}                 | ${{ path: ['src', 'file.vue'] }}
    `('matches route "$path" correctly', async ({ path, expectedParams }) => {
      const router = createRouter(basePath, escapedRef);
      await router.push(path);

      // Vue Router 3 returns string for repeatable params, Vue Router 4 returns array
      const actualParams = router.currentRoute.params;
      if (process.env.VUE_VERSION !== '3') {
        actualParams.path = actualParams.path ? actualParams.path.split('/') : '';
      }
      expect(actualParams).toEqual(expectedParams);
    });
  });
});
