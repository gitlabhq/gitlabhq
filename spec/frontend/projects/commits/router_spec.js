import { createRouter } from '~/projects/commits/router';

describe('Commits router spec', () => {
  const basePath = 'gitlab-org/gitlab/commits';
  const escapedRef = 'main';

  describe('route matching', () => {
    it.each`
      path                                    | expectedPath
      ${'/main/'}                             | ${''}
      ${'/main/README.md'}                    | ${'README.md'}
      ${'/main/app/assets'}                   | ${'app/assets'}
      ${'/main/app/assets/javascripts'}       | ${'app/assets/javascripts'}
      ${'/main/src/file%20with%20spaces.txt'} | ${'src/file with spaces.txt'}
      ${'/main/src/file.vue'}                 | ${'src/file.vue'}
    `('matches route "$path" correctly', async ({ path, expectedPath }) => {
      const router = createRouter(basePath, escapedRef);
      await router.push(path);

      // Vue Router 3 returns a string for repeatable params and Vue Router 4 an
      // array, so join them the way commit_list_app.vue does.
      const actualPath = [router.currentRoute.params.path ?? []].flat().join('/');

      expect(actualPath).toBe(expectedPath);
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
