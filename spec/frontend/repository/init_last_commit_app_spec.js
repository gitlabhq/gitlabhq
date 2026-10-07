import { createWrapper } from '@vue/test-utils';
import initLastCommitApp from '~/repository/init_last_commit_app';
import LastCommit from '~/repository/components/last_commit.vue';
import createRouter from '~/repository/router';

jest.mock('jh_else_ce/repository/components/tree_content.vue', () => ({
  name: 'TreeContent',
  template: '<div></div>',
}));
jest.mock('~/repository/components/blob_content_viewer.vue', () => ({
  name: 'BlobContentViewer',
  template: '<div></div>',
}));
jest.mock('~/repository/utils/dom');

describe('initLastCommitApp', () => {
  let app;
  let router;

  const createComponent = async (path = '/') => {
    router = createRouter('group/project', 'main', 'Project');
    await router.push(path).catch(() => {});
    app = initLastCommitApp(router);
    return app;
  };

  // Assert on what LastCommit receives rather than on the root's own computed
  // properties, so a regression to the raw route param fails here.
  const findLastCommit = () => createWrapper(app).findComponent(LastCommit);

  afterEach(() => {
    app?.$destroy();
    app = null;
  });

  describe('without a mount point', () => {
    it('returns null instead of mounting', async () => {
      document.body.innerHTML = '';

      expect(await createComponent()).toBe(null);
    });
  });

  describe('with a mount point', () => {
    beforeEach(() => {
      document.body.innerHTML =
        '<div id="js-last-commit" data-history-link="/group/project/-/commits/main"></div>';
    });

    it('mounts and passes the normalised path for the repository root', async () => {
      await createComponent('/');

      expect(findLastCommit().props('currentPath')).toBe('/');
    });

    it('passes the normalised path for a nested directory', async () => {
      await createComponent('/-/tree/main/lib/utils');

      expect(findLastCommit().props('currentPath')).toBe('lib/utils');
    });

    it('passes a history URL built from the mount point dataset and the current path', async () => {
      await createComponent('/-/tree/main/lib/utils');

      expect(new URL(findLastCommit().props('historyUrl')).pathname).toBe(
        '/group/project/-/commits/main/lib/utils',
      );
    });
  });
});
