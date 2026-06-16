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

  describe('commitsPathEncoded route', () => {
    it('matches the initial ref encoded with encodeURIComponent', async () => {
      const router = createRouter(basePath, escapedRef);
      // encodeURIComponent('main') === 'main' (no special chars), so this
      // just confirms the encoded route is wired up.
      await router.push(`/${encodeURIComponent(escapedRef)}/`);

      expect(router.currentRoute.name).toBe('commitsPath');
    });

    it('matches a slashed ref encoded with encodeURIComponent', async () => {
      const slashedRef = 'feature/my-branch';
      const router = createRouter(basePath, slashedRef);
      await router.push(`/${encodeURIComponent(slashedRef)}/`);

      expect(router.currentRoute.name).toBe('commitsPathEncoded');
    });
  });

  describe('commitsAnyRef fallback', () => {
    it('captures the encoded ref as a single param for refs with slashes', async () => {
      const router = createRouter(basePath, escapedRef);
      const encodedRef = encodeURIComponent('feature/foo');
      await router.push(`/${encodedRef}/app/models/user.rb`);

      expect(router.currentRoute.name).toBe('commitsAnyRef');
      // Vue Router auto-decodes params, so we get the decoded ref back.
      // The important thing is that it's captured as a single param, not split.
      expect(router.currentRoute.params.ref).toBe('feature/foo');
    });
  });
});
