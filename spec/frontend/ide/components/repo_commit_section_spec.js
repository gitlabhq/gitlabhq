import { mount } from '@vue/test-utils';
import { createStore } from '~/ide/stores';
import router from '~/ide/ide_router';
import RepoCommitSection from '~/ide/components/repo_commit_section.vue';
import { stageKeys } from '~/ide/constants';
import { file } from '../helpers';

const TEST_NO_CHANGES_SVG = 'nochangessvg';

describe('RepoCommitSection', () => {
  let wrapper;
  let store;

  function createComponent() {
    wrapper = mount(RepoCommitSection, { store });
  }

  function setupDefaultState() {
    store.state.noChangesStateSvgPath = 'svg';
    store.state.committedStateSvgPath = 'commitsvg';
    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'master';
    store.state.projects.abcproject = {
      web_url: '',
      branches: {
        master: {
          workingReference: '1',
        },
      },
    };

    const files = [file('file1'), file('file2')].map(f =>
      Object.assign(f, {
        type: 'blob',
        content: 'orginal content',
      }),
    );

    store.state.rightPanelCollapsed = false;
    store.state.currentBranch = 'master';
    store.state.changedFiles = [];
    store.state.stagedFiles = [{ ...files[0] }, { ...files[1] }];
    store.state.stagedFiles.forEach(f =>
      Object.assign(f, {
        changed: true,
        staged: true,
        content: 'testing',
      }),
    );

    files.forEach(f => {
      store.state.entries[f.path] = f;
    });
  }

  beforeEach(() => {
    store = createStore();

    jest.spyOn(store, 'dispatch');
    jest.spyOn(router, 'push').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('empty Stage', () => {
    beforeEach(() => {
      store.state.noChangesStateSvgPath = TEST_NO_CHANGES_SVG;
      store.state.committedStateSvgPath = 'svg';

      createComponent();
    });

    it('renders no changes text', () => {
      expect(
        wrapper
          .find('.js-empty-state')
          .text()
          .trim(),
      ).toContain('No changes');
      expect(wrapper.find('.js-empty-state img').attributes('src')).toBe(TEST_NO_CHANGES_SVG);
    });
  });

  describe('default', () => {
    beforeEach(() => {
      setupDefaultState();

      createComponent();
    });

    it('opens last opened file', () => {
      expect(store.state.openFiles.length).toBe(1);
      expect(store.state.openFiles[0].pending).toBe(true);
    });

    it('calls openPendingTab', () => {
      expect(store.dispatch).toHaveBeenCalledWith('openPendingTab', {
        file: store.getters.lastOpenedFile,
        keyPrefix: stageKeys.staged,
      });
    });

    it('renders a commit section', () => {
      const allFiles = store.state.changedFiles.concat(store.state.stagedFiles);
      const changedFileNames = wrapper
        .findAll('.multi-file-commit-list > li')
        .wrappers.map(x => x.text().trim());

      expect(changedFileNames).toEqual(allFiles.map(x => x.path));
    });
  });

  describe('with unstaged file', () => {
    beforeEach(() => {
      setupDefaultState();

      store.state.changedFiles = store.state.stagedFiles.map(x =>
        Object.assign(x, { staged: false }),
      );
      store.state.stagedFiles = [];

      createComponent();
    });

    it('calls openPendingTab with unstaged prefix', () => {
      expect(store.dispatch).toHaveBeenCalledWith('openPendingTab', {
        file: store.getters.lastOpenedFile,
        keyPrefix: stageKeys.unstaged,
      });
    });
  });
});
