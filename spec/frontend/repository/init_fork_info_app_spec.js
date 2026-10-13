import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import initForkInfoApp from '~/repository/init_fork_info_app';
import ForkInfo from '~/repository/components/fork_info.vue';

// $destroy() is inert for an app built by initVueApp on Vue 3, and $children
// only exists through the compat build, so assert on the mount call instead.
jest.mock('~/lib/utils/vue3compat/init_vue_app');

describe('initForkInfoApp', () => {
  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe('without a mount point', () => {
    it('returns null instead of mounting', () => {
      expect(initForkInfoApp()).toBe(null);
      expect(initVueApp).not.toHaveBeenCalled();
    });
  });

  describe('with a mount point', () => {
    beforeEach(() => {
      document.body.innerHTML = `
        <div id="js-fork-info"
          data-project-path="group/project"
          data-selected-branch="main"
          data-source-name="Upstream Project"
          data-source-path="/upstream/project"
          data-source-default-branch="main"
          data-can-sync-branch="true"
          data-ahead-compare-path="/ahead"
          data-behind-compare-path="/behind"
          data-create-mr-path="/create"
          data-view-mr-path="/view"></div>`;
    });

    it('mounts ForkInfo with the dataset, parsing canSyncBranch', () => {
      initForkInfoApp();

      expect(initVueApp).toHaveBeenCalledWith(
        expect.objectContaining({
          el: document.getElementById('js-fork-info'),
          component: ForkInfo,
          props: {
            canSyncBranch: true,
            projectPath: 'group/project',
            selectedBranch: 'main',
            sourceName: 'Upstream Project',
            sourcePath: '/upstream/project',
            sourceDefaultBranch: 'main',
            aheadComparePath: '/ahead',
            behindComparePath: '/behind',
            createMrPath: '/create',
            viewMrPath: '/view',
          },
        }),
      );
    });
  });
});
