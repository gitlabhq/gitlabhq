import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlLoadingIcon, GlPagination } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'spec/test_constants';
import Mousetrap from 'mousetrap';
import App from '~/diffs/components/app.vue';
import NoChanges from '~/diffs/components/no_changes.vue';
import DiffFile from '~/diffs/components/diff_file.vue';
import CompareVersions from '~/diffs/components/compare_versions.vue';
import HiddenFilesWarning from '~/diffs/components/hidden_files_warning.vue';
import CollapsedFilesWarning from '~/diffs/components/collapsed_files_warning.vue';
import CommitWidget from '~/diffs/components/commit_widget.vue';
import TreeList from '~/diffs/components/tree_list.vue';
import createDiffsStore from '../create_diffs_store';
import axios from '~/lib/utils/axios_utils';
import * as urlUtils from '~/lib/utils/url_utility';
import diffsMockData from '../mock_data/merge_request_diffs';

const mergeRequestDiff = { version_index: 1 };
const TEST_ENDPOINT = `${TEST_HOST}/diff/endpoint`;
const COMMIT_URL = '[BASE URL]/OLD';
const UPDATED_COMMIT_URL = '[BASE URL]/NEW';

function getCollapsedFilesWarning(wrapper) {
  return wrapper.find(CollapsedFilesWarning);
}

describe('diffs/components/app', () => {
  const oldMrTabs = window.mrTabs;
  let store;
  let wrapper;
  let mock;

  function createComponent(props = {}, extendStore = () => {}, provisions = {}) {
    const localVue = createLocalVue();
    const provide = {
      ...provisions,
      glFeatures: {
        ...(provisions.glFeatures || {}),
      },
    };

    localVue.use(Vuex);

    store = createDiffsStore();
    store.state.diffs.isLoading = false;
    store.state.diffs.isTreeLoaded = true;

    extendStore(store);

    wrapper = shallowMount(localVue.extend(App), {
      localVue,
      propsData: {
        endpoint: TEST_ENDPOINT,
        endpointMetadata: `${TEST_HOST}/diff/endpointMetadata`,
        endpointBatch: `${TEST_HOST}/diff/endpointBatch`,
        endpointCoverage: `${TEST_HOST}/diff/endpointCoverage`,
        projectPath: 'namespace/project',
        currentUser: {},
        changesEmptyStateIllustration: '',
        dismissEndpoint: '',
        showSuggestPopover: true,
        viewDiffsFileByFile: false,
        ...props,
      },
      provide,
      store,
      methods: {
        isLatestVersion() {
          return true;
        },
      },
    });
  }

  beforeEach(() => {
    // setup globals (needed for component to mount :/)
    window.mrTabs = {
      resetViewContainer: jest.fn(),
    };
    window.mrTabs.expandViewContainer = jest.fn();
    mock = new MockAdapter(axios);
    mock.onGet(TEST_ENDPOINT).reply(200, {});
  });

  afterEach(() => {
    // reset globals
    window.mrTabs = oldMrTabs;

    // reset component
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }

    mock.restore();
  });

  describe('fetch diff methods', () => {
    beforeEach(done => {
      const fetchResolver = () => {
        store.state.diffs.retrievingBatches = false;
        store.state.notes.discussions = 'test';
        return Promise.resolve({ real_size: 100 });
      };
      jest.spyOn(window, 'requestIdleCallback').mockImplementation(fn => fn());
      createComponent();
      jest.spyOn(wrapper.vm, 'fetchDiffFilesMeta').mockImplementation(fetchResolver);
      jest.spyOn(wrapper.vm, 'fetchDiffFilesBatch').mockImplementation(fetchResolver);
      jest.spyOn(wrapper.vm, 'fetchCoverageFiles').mockImplementation(fetchResolver);
      jest.spyOn(wrapper.vm, 'setDiscussions').mockImplementation(() => {});
      jest.spyOn(wrapper.vm, 'startRenderDiffsQueue').mockImplementation(() => {});
      jest.spyOn(wrapper.vm, 'unwatchDiscussions').mockImplementation(() => {});
      jest.spyOn(wrapper.vm, 'unwatchRetrievingBatches').mockImplementation(() => {});
      store.state.diffs.retrievingBatches = true;
      store.state.diffs.diffFiles = [];
      wrapper.vm.$nextTick(done);
    });

    it('calls batch methods if diffsBatchLoad is enabled, and not latest version', done => {
      expect(wrapper.vm.diffFilesLength).toEqual(0);
      wrapper.vm.isLatestVersion = () => false;
      wrapper.vm.fetchData(false);

      setImmediate(() => {
        expect(wrapper.vm.startRenderDiffsQueue).toHaveBeenCalled();
        expect(wrapper.vm.fetchDiffFilesMeta).toHaveBeenCalled();
        expect(wrapper.vm.fetchDiffFilesBatch).toHaveBeenCalled();
        expect(wrapper.vm.fetchCoverageFiles).toHaveBeenCalled();
        expect(wrapper.vm.unwatchDiscussions).toHaveBeenCalled();
        expect(wrapper.vm.diffFilesLength).toEqual(100);
        expect(wrapper.vm.unwatchRetrievingBatches).toHaveBeenCalled();
        done();
      });
    });

    it('calls batch methods if diffsBatchLoad is enabled, and latest version', done => {
      expect(wrapper.vm.diffFilesLength).toEqual(0);
      wrapper.vm.fetchData(false);

      setImmediate(() => {
        expect(wrapper.vm.startRenderDiffsQueue).toHaveBeenCalled();
        expect(wrapper.vm.fetchDiffFilesMeta).toHaveBeenCalled();
        expect(wrapper.vm.fetchDiffFilesBatch).toHaveBeenCalled();
        expect(wrapper.vm.fetchCoverageFiles).toHaveBeenCalled();
        expect(wrapper.vm.unwatchDiscussions).toHaveBeenCalled();
        expect(wrapper.vm.diffFilesLength).toEqual(100);
        expect(wrapper.vm.unwatchRetrievingBatches).toHaveBeenCalled();
        done();
      });
    });
  });

  it('adds container-limiting classes when showFileTree is false with inline diffs', () => {
    createComponent({}, ({ state }) => {
      state.diffs.showTreeList = false;
      state.diffs.isParallelView = false;
    });

    expect(wrapper.find('.container-limited.limit-container-width').exists()).toBe(true);
  });

  it('does not add container-limiting classes when showFileTree is false with inline diffs', () => {
    createComponent({}, ({ state }) => {
      state.diffs.showTreeList = true;
      state.diffs.isParallelView = false;
    });

    expect(wrapper.find('.container-limited.limit-container-width').exists()).toBe(false);
  });

  it('does not add container-limiting classes when isFluidLayout', () => {
    createComponent({ isFluidLayout: true }, ({ state }) => {
      state.diffs.isParallelView = false;
    });

    expect(wrapper.find('.container-limited.limit-container-width').exists()).toBe(false);
  });

  it('displays loading icon on loading', () => {
    createComponent({}, ({ state }) => {
      state.diffs.isLoading = true;
    });

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('displays loading icon on batch loading', () => {
    createComponent({}, ({ state }) => {
      state.diffs.isBatchLoading = true;
    });

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('displays diffs container when not loading', () => {
    createComponent();

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
    expect(wrapper.find('#diffs').exists()).toBe(true);
  });

  it('does not show commit info', () => {
    createComponent();

    expect(wrapper.find('.blob-commit-info').exists()).toBe(false);
  });

  describe('row highlighting', () => {
    beforeEach(() => {
      window.location.hash = 'ABC_123';
    });

    it('sets highlighted row if hash exists in location object', done => {
      createComponent({
        shouldShow: true,
      });

      // Component uses $nextTick so we wait until that has finished
      setImmediate(() => {
        expect(store.state.diffs.highlightedRow).toBe('ABC_123');

        done();
      });
    });

    it('marks current diff file based on currently highlighted row', () => {
      createComponent({
        shouldShow: true,
      });

      // Component uses $nextTick so we wait until that has finished
      return wrapper.vm.$nextTick().then(() => {
        expect(store.state.diffs.currentDiffFileId).toBe('ABC');
      });
    });
  });

  describe('resizable', () => {
    afterEach(() => {
      localStorage.removeItem('mr_tree_list_width');
    });

    it('sets initial width when no localStorage has been set', () => {
      createComponent();

      expect(wrapper.vm.treeWidth).toEqual(320);
    });

    it('sets initial width to localStorage size', () => {
      localStorage.setItem('mr_tree_list_width', '200');

      createComponent();

      expect(wrapper.vm.treeWidth).toEqual(200);
    });

    it('sets width of tree list', () => {
      createComponent();

      expect(wrapper.find('.js-diff-tree-list').element.style.width).toEqual('320px');
    });
  });

  it('marks current diff file based on currently highlighted row', done => {
    createComponent({
      shouldShow: true,
    });

    // Component uses $nextTick so we wait until that has finished
    setImmediate(() => {
      expect(store.state.diffs.currentDiffFileId).toBe('ABC');

      done();
    });
  });

  describe('empty state', () => {
    it('renders empty state when no diff files exist', () => {
      createComponent();

      expect(wrapper.find(NoChanges).exists()).toBe(true);
    });

    it('does not render empty state when diff files exist', () => {
      createComponent({}, ({ state }) => {
        state.diffs.diffFiles.push({
          id: 1,
        });
      });

      expect(wrapper.find(NoChanges).exists()).toBe(false);
      expect(wrapper.findAll(DiffFile).length).toBe(1);
    });

    it('does not render empty state when versions match', () => {
      createComponent({}, ({ state }) => {
        state.diffs.startVersion = mergeRequestDiff;
        state.diffs.mergeRequestDiff = mergeRequestDiff;
      });

      expect(wrapper.find(NoChanges).exists()).toBe(false);
    });
  });

  describe('keyboard shortcut navigation', () => {
    let spies = [];
    let jumpSpy;
    let moveSpy;

    function setup(componentProps, featureFlags) {
      createComponent(
        componentProps,
        ({ state }) => {
          state.diffs.commit = { id: 'SHA123' };
        },
        { glFeatures: { mrCommitNeighborNav: true, ...featureFlags } },
      );

      moveSpy = jest.spyOn(wrapper.vm, 'moveToNeighboringCommit').mockImplementation(() => {});
      jumpSpy = jest.fn();
      spies = [jumpSpy, moveSpy];
      wrapper.setMethods({
        jumpToFile: jumpSpy,
      });
    }

    describe('visible app', () => {
      it.each`
        key    | name                         | spy  | args                           | featureFlags
        ${'['} | ${'jumpToFile'}              | ${0} | ${[-1]}                        | ${{}}
        ${'k'} | ${'jumpToFile'}              | ${0} | ${[-1]}                        | ${{}}
        ${']'} | ${'jumpToFile'}              | ${0} | ${[+1]}                        | ${{}}
        ${'j'} | ${'jumpToFile'}              | ${0} | ${[+1]}                        | ${{}}
        ${'x'} | ${'moveToNeighboringCommit'} | ${1} | ${[{ direction: 'previous' }]} | ${{ mrCommitNeighborNav: true }}
        ${'c'} | ${'moveToNeighboringCommit'} | ${1} | ${[{ direction: 'next' }]}     | ${{ mrCommitNeighborNav: true }}
      `(
        'calls `$name()` with correct parameters whenever the "$key" key is pressed',
        ({ key, spy, args, featureFlags }) => {
          setup({ shouldShow: true }, featureFlags);

          return wrapper.vm.$nextTick().then(() => {
            expect(spies[spy]).not.toHaveBeenCalled();

            Mousetrap.trigger(key);

            expect(spies[spy]).toHaveBeenCalledWith(...args);
          });
        },
      );

      it.each`
        key    | name                         | spy  | featureFlags
        ${'x'} | ${'moveToNeighboringCommit'} | ${1} | ${{ mrCommitNeighborNav: false }}
        ${'c'} | ${'moveToNeighboringCommit'} | ${1} | ${{ mrCommitNeighborNav: false }}
      `(
        'does not call `$name()` even when the correct key is pressed if the feature flag is disabled',
        ({ key, spy, featureFlags }) => {
          setup({ shouldShow: true }, featureFlags);

          return wrapper.vm.$nextTick().then(() => {
            expect(spies[spy]).not.toHaveBeenCalled();

            Mousetrap.trigger(key);

            expect(spies[spy]).not.toHaveBeenCalled();
          });
        },
      );

      it.each`
        key    | name                         | spy  | allowed
        ${'d'} | ${'jumpToFile'}              | ${0} | ${['[', ']', 'j', 'k']}
        ${'r'} | ${'moveToNeighboringCommit'} | ${1} | ${['x', 'c']}
      `(
        `does not call \`$name()\` when a key that is not one of \`$allowed\` is pressed`,
        ({ key, spy }) => {
          setup({ shouldShow: true }, { mrCommitNeighborNav: true });

          return wrapper.vm.$nextTick().then(() => {
            Mousetrap.trigger(key);

            expect(spies[spy]).not.toHaveBeenCalled();
          });
        },
      );
    });

    describe('hidden app', () => {
      beforeEach(() => {
        setup({ shouldShow: false }, { mrCommitNeighborNav: true });

        return wrapper.vm.$nextTick().then(() => {
          Mousetrap.reset();
        });
      });

      it.each`
        key    | name                         | spy
        ${'['} | ${'jumpToFile'}              | ${0}
        ${'k'} | ${'jumpToFile'}              | ${0}
        ${']'} | ${'jumpToFile'}              | ${0}
        ${'j'} | ${'jumpToFile'}              | ${0}
        ${'x'} | ${'moveToNeighboringCommit'} | ${1}
        ${'c'} | ${'moveToNeighboringCommit'} | ${1}
      `('stops calling `$name()` when the app is hidden', ({ key, spy }) => {
        Mousetrap.trigger(key);

        expect(spies[spy]).not.toHaveBeenCalled();
      });
    });
  });

  describe('jumpToFile', () => {
    let spy;

    beforeEach(() => {
      spy = jest.fn();

      createComponent({}, () => {
        store.state.diffs.diffFiles = [
          { file_hash: '111', file_path: '111.js' },
          { file_hash: '222', file_path: '222.js' },
          { file_hash: '333', file_path: '333.js' },
        ];
      });

      wrapper.setMethods({
        scrollToFile: spy,
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('jumps to next and previous files in the list', done => {
      wrapper.vm
        .$nextTick()
        .then(() => {
          wrapper.vm.jumpToFile(+1);

          expect(spy.mock.calls[spy.mock.calls.length - 1]).toEqual(['222.js']);
          store.state.diffs.currentDiffFileId = '222';
          wrapper.vm.jumpToFile(+1);

          expect(spy.mock.calls[spy.mock.calls.length - 1]).toEqual(['333.js']);
          store.state.diffs.currentDiffFileId = '333';
          wrapper.vm.jumpToFile(-1);

          expect(spy.mock.calls[spy.mock.calls.length - 1]).toEqual(['222.js']);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not jump to previous file from the first one', done => {
      wrapper.vm
        .$nextTick()
        .then(() => {
          store.state.diffs.currentDiffFileId = '333';

          expect(wrapper.vm.currentDiffIndex).toEqual(2);

          wrapper.vm.jumpToFile(+1);

          expect(wrapper.vm.currentDiffIndex).toEqual(2);
          expect(spy).not.toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not jump to next file from the last one', done => {
      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.vm.currentDiffIndex).toEqual(0);

          wrapper.vm.jumpToFile(-1);

          expect(wrapper.vm.currentDiffIndex).toEqual(0);
          expect(spy).not.toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('commit watcher', () => {
    const spy = () => {
      jest.spyOn(wrapper.vm, 'refetchDiffData').mockImplementation(() => {});
      jest.spyOn(wrapper.vm, 'adjustView').mockImplementation(() => {});
    };
    let location;

    beforeAll(() => {
      location = window.location;
      delete window.location;
      window.location = COMMIT_URL;
      document.title = 'My Title';
    });

    beforeEach(() => {
      jest.spyOn(urlUtils, 'updateHistory');
    });

    afterAll(() => {
      window.location = location;
    });

    it('when the commit changes and the app is not loading it should update the history, refetch the diff data, and update the view', () => {
      createComponent({}, ({ state }) => {
        state.diffs.commit = { ...state.diffs.commit, id: 'OLD' };
      });
      spy();

      store.state.diffs.commit = { id: 'NEW' };

      return wrapper.vm.$nextTick().then(() => {
        expect(urlUtils.updateHistory).toHaveBeenCalledWith({
          title: document.title,
          url: UPDATED_COMMIT_URL,
        });
        expect(wrapper.vm.refetchDiffData).toHaveBeenCalled();
        expect(wrapper.vm.adjustView).toHaveBeenCalled();
      });
    });

    it.each`
      isLoading | oldSha   | newSha
      ${true}   | ${'OLD'} | ${'NEW'}
      ${false}  | ${'NEW'} | ${'NEW'}
    `(
      'given `{ "isLoading": $isLoading, "oldSha": "$oldSha", "newSha": "$newSha" }`, nothing should happen',
      ({ isLoading, oldSha, newSha }) => {
        createComponent({}, ({ state }) => {
          state.diffs.isLoading = isLoading;
          state.diffs.commit = { ...state.diffs.commit, id: oldSha };
        });
        spy();

        store.state.diffs.commit = { id: newSha };

        return wrapper.vm.$nextTick().then(() => {
          expect(urlUtils.updateHistory).not.toHaveBeenCalled();
          expect(wrapper.vm.refetchDiffData).not.toHaveBeenCalled();
          expect(wrapper.vm.adjustView).not.toHaveBeenCalled();
        });
      },
    );
  });

  describe('diffs', () => {
    it('should render compare versions component', () => {
      createComponent({}, ({ state }) => {
        state.diffs.mergeRequestDiffs = diffsMockData;
        state.diffs.targetBranchName = 'target-branch';
        state.diffs.mergeRequestDiff = mergeRequestDiff;
      });

      expect(wrapper.find(CompareVersions).exists()).toBe(true);
      expect(wrapper.find(CompareVersions).props()).toEqual(
        expect.objectContaining({
          mergeRequestDiffs: diffsMockData,
        }),
      );
    });

    describe('warnings', () => {
      describe('hidden files', () => {
        it('should render hidden files warning if render overflow warning is present', () => {
          createComponent({}, ({ state }) => {
            state.diffs.renderOverflowWarning = true;
            state.diffs.realSize = '5';
            state.diffs.plainDiffPath = 'plain diff path';
            state.diffs.emailPatchPath = 'email patch path';
            state.diffs.size = 1;
          });

          expect(wrapper.find(HiddenFilesWarning).exists()).toBe(true);
          expect(wrapper.find(HiddenFilesWarning).props()).toEqual(
            expect.objectContaining({
              total: '5',
              plainDiffPath: 'plain diff path',
              emailPatchPath: 'email patch path',
              visible: 1,
            }),
          );
        });
      });

      describe('collapsed files', () => {
        it('should render the collapsed files warning if there are any automatically collapsed files', () => {
          createComponent({}, ({ state }) => {
            state.diffs.diffFiles = [{ viewer: { automaticallyCollapsed: true } }];
          });

          expect(getCollapsedFilesWarning(wrapper).exists()).toBe(true);
        });

        it('should not render the collapsed files warning if there are no automatically collapsed files', () => {
          createComponent({}, ({ state }) => {
            state.diffs.diffFiles = [
              { viewer: { automaticallyCollapsed: false, manuallyCollapsed: true } },
              { viewer: { automaticallyCollapsed: false, manuallyCollapsed: false } },
            ];
          });

          expect(getCollapsedFilesWarning(wrapper).exists()).toBe(false);
        });
      });
    });

    it('should display commit widget if store has a commit', () => {
      createComponent({}, () => {
        store.state.diffs.commit = {
          author: 'John Doe',
        };
      });

      expect(wrapper.find(CommitWidget).exists()).toBe(true);
    });

    it('should display diff file if there are diff files', () => {
      createComponent({}, ({ state }) => {
        state.diffs.diffFiles.push({ sha: '123' });
      });

      expect(wrapper.find(DiffFile).exists()).toBe(true);
    });

    it('should render tree list', () => {
      createComponent();

      expect(wrapper.find(TreeList).exists()).toBe(true);
    });
  });

  describe('setTreeDisplay', () => {
    let setShowTreeList;

    beforeEach(() => {
      setShowTreeList = jest.fn();
    });

    afterEach(() => {
      localStorage.removeItem('mr_tree_show');
    });

    it('calls setShowTreeList when only 1 file', () => {
      createComponent({}, ({ state }) => {
        state.diffs.diffFiles.push({ sha: '123' });
      });

      wrapper.setMethods({
        setShowTreeList,
      });

      wrapper.vm.setTreeDisplay();

      expect(setShowTreeList).toHaveBeenCalledWith({ showTreeList: false, saving: false });
    });

    it('calls setShowTreeList with true when more than 1 file is in diffs array', () => {
      createComponent({}, ({ state }) => {
        state.diffs.diffFiles.push({ sha: '123' });
        state.diffs.diffFiles.push({ sha: '124' });
      });

      wrapper.setMethods({
        setShowTreeList,
      });

      wrapper.vm.setTreeDisplay();

      expect(setShowTreeList).toHaveBeenCalledWith({ showTreeList: true, saving: false });
    });

    it.each`
      showTreeList
      ${true}
      ${false}
    `('calls setShowTreeList with localstorage $showTreeList', ({ showTreeList }) => {
      localStorage.setItem('mr_tree_show', showTreeList);

      createComponent({}, ({ state }) => {
        state.diffs.diffFiles.push({ sha: '123' });
      });

      wrapper.setMethods({
        setShowTreeList,
      });

      wrapper.vm.setTreeDisplay();

      expect(setShowTreeList).toHaveBeenCalledWith({ showTreeList, saving: false });
    });
  });

  describe('file-by-file', () => {
    it('renders a single diff', () => {
      createComponent({ viewDiffsFileByFile: true }, ({ state }) => {
        state.diffs.diffFiles.push({ file_hash: '123' });
        state.diffs.diffFiles.push({ file_hash: '312' });
      });

      expect(wrapper.findAll(DiffFile).length).toBe(1);
    });

    describe('pagination', () => {
      const fileByFileNav = () => wrapper.find('[data-testid="file-by-file-navigation"]');
      const paginator = () => fileByFileNav().find(GlPagination);

      it('sets previous button as disabled', () => {
        createComponent({ viewDiffsFileByFile: true }, ({ state }) => {
          state.diffs.diffFiles.push({ file_hash: '123' }, { file_hash: '312' });
        });

        expect(paginator().attributes('prevpage')).toBe(undefined);
        expect(paginator().attributes('nextpage')).toBe('2');
      });

      it('sets next button as disabled', () => {
        createComponent({ viewDiffsFileByFile: true }, ({ state }) => {
          state.diffs.diffFiles.push({ file_hash: '123' }, { file_hash: '312' });
          state.diffs.currentDiffFileId = '312';
        });

        expect(paginator().attributes('prevpage')).toBe('1');
        expect(paginator().attributes('nextpage')).toBe(undefined);
      });

      it("doesn't display when there's fewer than 2 files", () => {
        createComponent({ viewDiffsFileByFile: true }, ({ state }) => {
          state.diffs.diffFiles.push({ file_hash: '123' });
          state.diffs.currentDiffFileId = '123';
        });

        expect(fileByFileNav().exists()).toBe(false);
      });

      it.each`
        currentDiffFileId | targetFile
        ${'123'}          | ${2}
        ${'312'}          | ${1}
      `(
        'it calls navigateToDiffFileIndex with $index when $link is clicked',
        async ({ currentDiffFileId, targetFile }) => {
          createComponent({ viewDiffsFileByFile: true }, ({ state }) => {
            state.diffs.diffFiles.push({ file_hash: '123' }, { file_hash: '312' });
            state.diffs.currentDiffFileId = currentDiffFileId;
          });

          jest.spyOn(wrapper.vm, 'navigateToDiffFileIndex');

          paginator().vm.$emit('input', targetFile);

          await wrapper.vm.$nextTick();

          expect(wrapper.vm.navigateToDiffFileIndex).toHaveBeenCalledWith(targetFile - 1);
        },
      );
    });
  });
});
