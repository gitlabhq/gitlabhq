import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'spec/test_constants';
import Mousetrap from 'mousetrap';
import App from '~/diffs/components/app.vue';
import NoChanges from '~/diffs/components/no_changes.vue';
import DiffFile from '~/diffs/components/diff_file.vue';
import CompareVersions from '~/diffs/components/compare_versions.vue';
import HiddenFilesWarning from '~/diffs/components/hidden_files_warning.vue';
import CommitWidget from '~/diffs/components/commit_widget.vue';
import TreeList from '~/diffs/components/tree_list.vue';
import { INLINE_DIFF_VIEW_TYPE, PARALLEL_DIFF_VIEW_TYPE } from '~/diffs/constants';
import createDiffsStore from '../create_diffs_store';
import axios from '~/lib/utils/axios_utils';
import * as urlUtils from '~/lib/utils/url_utility';
import diffsMockData from '../mock_data/merge_request_diffs';

const mergeRequestDiff = { version_index: 1 };
const TEST_ENDPOINT = `${TEST_HOST}/diff/endpoint`;
const COMMIT_URL = '[BASE URL]/OLD';
const UPDATED_COMMIT_URL = '[BASE URL]/NEW';

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

  function getOppositeViewType(currentViewType) {
    return currentViewType === INLINE_DIFF_VIEW_TYPE
      ? PARALLEL_DIFF_VIEW_TYPE
      : INLINE_DIFF_VIEW_TYPE;
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
      jest.spyOn(wrapper.vm, 'fetchDiffFiles').mockImplementation(fetchResolver);
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

    describe('when the diff view type changes and it should load a single diff view style', () => {
      const noLinesDiff = {
        highlighted_diff_lines: [],
        parallel_diff_lines: [],
      };
      const parallelLinesDiff = {
        highlighted_diff_lines: [],
        parallel_diff_lines: ['line'],
      };
      const inlineLinesDiff = {
        highlighted_diff_lines: ['line'],
        parallel_diff_lines: [],
      };
      const fullDiff = {
        highlighted_diff_lines: ['line'],
        parallel_diff_lines: ['line'],
      };

      function expectFetchToOccur({
        vueInstance,
        done = () => {},
        batch = false,
        existingFiles = 1,
      } = {}) {
        vueInstance.$nextTick(() => {
          expect(vueInstance.diffFiles.length).toEqual(existingFiles);

          if (!batch) {
            expect(vueInstance.fetchDiffFiles).toHaveBeenCalled();
            expect(vueInstance.fetchDiffFilesBatch).not.toHaveBeenCalled();
          } else {
            expect(vueInstance.fetchDiffFiles).not.toHaveBeenCalled();
            expect(vueInstance.fetchDiffFilesBatch).toHaveBeenCalled();
          }

          done();
        });
      }

      beforeEach(() => {
        wrapper.vm.glFeatures.singleMrDiffView = true;
      });

      it('fetches diffs if it has none', done => {
        wrapper.vm.isLatestVersion = () => false;

        store.state.diffs.diffViewType = getOppositeViewType(wrapper.vm.diffViewType);

        expectFetchToOccur({ vueInstance: wrapper.vm, batch: false, existingFiles: 0, done });
      });

      it('fetches diffs if it has both view styles, but no lines in either', done => {
        wrapper.vm.isLatestVersion = () => false;

        store.state.diffs.diffFiles.push(noLinesDiff);
        store.state.diffs.diffViewType = getOppositeViewType(wrapper.vm.diffViewType);

        expectFetchToOccur({ vueInstance: wrapper.vm, done });
      });

      it('fetches diffs if it only has inline view style', done => {
        wrapper.vm.isLatestVersion = () => false;

        store.state.diffs.diffFiles.push(inlineLinesDiff);
        store.state.diffs.diffViewType = getOppositeViewType(wrapper.vm.diffViewType);

        expectFetchToOccur({ vueInstance: wrapper.vm, done });
      });

      it('fetches diffs if it only has parallel view style', done => {
        wrapper.vm.isLatestVersion = () => false;

        store.state.diffs.diffFiles.push(parallelLinesDiff);
        store.state.diffs.diffViewType = getOppositeViewType(wrapper.vm.diffViewType);

        expectFetchToOccur({ vueInstance: wrapper.vm, done });
      });

      it('fetches batch diffs if it has none', done => {
        wrapper.vm.glFeatures.diffsBatchLoad = true;

        store.state.diffs.diffViewType = getOppositeViewType(wrapper.vm.diffViewType);

        expectFetchToOccur({ vueInstance: wrapper.vm, batch: true, existingFiles: 0, done });
      });

      it('fetches batch diffs if it has both view styles, but no lines in either', done => {
        wrapper.vm.glFeatures.diffsBatchLoad = true;

        store.state.diffs.diffFiles.push(noLinesDiff);
        store.state.diffs.diffViewType = getOppositeViewType(wrapper.vm.diffViewType);

        expectFetchToOccur({ vueInstance: wrapper.vm, batch: true, done });
      });

      it('fetches batch diffs if it only has inline view style', done => {
        wrapper.vm.glFeatures.diffsBatchLoad = true;

        store.state.diffs.diffFiles.push(inlineLinesDiff);
        store.state.diffs.diffViewType = getOppositeViewType(wrapper.vm.diffViewType);

        expectFetchToOccur({ vueInstance: wrapper.vm, batch: true, done });
      });

      it('fetches batch diffs if it only has parallel view style', done => {
        wrapper.vm.glFeatures.diffsBatchLoad = true;

        store.state.diffs.diffFiles.push(parallelLinesDiff);
        store.state.diffs.diffViewType = getOppositeViewType(wrapper.vm.diffViewType);

        expectFetchToOccur({ vueInstance: wrapper.vm, batch: true, done });
      });

      it('does not fetch diffs if it has already fetched both styles of diff', () => {
        wrapper.vm.glFeatures.diffsBatchLoad = false;

        store.state.diffs.diffFiles.push(fullDiff);
        store.state.diffs.diffViewType = getOppositeViewType(wrapper.vm.diffViewType);

        expect(wrapper.vm.diffFiles.length).toEqual(1);
        expect(wrapper.vm.fetchDiffFiles).not.toHaveBeenCalled();
        expect(wrapper.vm.fetchDiffFilesBatch).not.toHaveBeenCalled();
      });

      it('does not fetch batch diffs if it has already fetched both styles of diff', () => {
        wrapper.vm.glFeatures.diffsBatchLoad = true;

        store.state.diffs.diffFiles.push(fullDiff);
        store.state.diffs.diffViewType = getOppositeViewType(wrapper.vm.diffViewType);

        expect(wrapper.vm.diffFiles.length).toEqual(1);
        expect(wrapper.vm.fetchDiffFiles).not.toHaveBeenCalled();
        expect(wrapper.vm.fetchDiffFilesBatch).not.toHaveBeenCalled();
      });
    });

    it('calls fetchDiffFiles if diffsBatchLoad is not enabled', done => {
      expect(wrapper.vm.diffFilesLength).toEqual(0);
      wrapper.vm.glFeatures.diffsBatchLoad = false;
      wrapper.vm.fetchData(false);

      expect(wrapper.vm.fetchDiffFiles).toHaveBeenCalled();
      setImmediate(() => {
        expect(wrapper.vm.startRenderDiffsQueue).toHaveBeenCalled();
        expect(wrapper.vm.fetchDiffFilesMeta).not.toHaveBeenCalled();
        expect(wrapper.vm.fetchDiffFilesBatch).not.toHaveBeenCalled();
        expect(wrapper.vm.fetchCoverageFiles).toHaveBeenCalled();
        expect(wrapper.vm.unwatchDiscussions).toHaveBeenCalled();
        expect(wrapper.vm.diffFilesLength).toEqual(100);
        expect(wrapper.vm.unwatchRetrievingBatches).toHaveBeenCalled();

        done();
      });
    });

    it('calls batch methods if diffsBatchLoad is enabled, and not latest version', done => {
      expect(wrapper.vm.diffFilesLength).toEqual(0);
      wrapper.vm.glFeatures.diffsBatchLoad = true;
      wrapper.vm.isLatestVersion = () => false;
      wrapper.vm.fetchData(false);

      expect(wrapper.vm.fetchDiffFiles).not.toHaveBeenCalled();
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
      wrapper.vm.glFeatures.diffsBatchLoad = true;
      wrapper.vm.fetchData(false);

      expect(wrapper.vm.fetchDiffFiles).not.toHaveBeenCalled();
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

    expect(wrapper.contains('.container-limited.limit-container-width')).toBe(true);
  });

  it('does not add container-limiting classes when showFileTree is false with inline diffs', () => {
    createComponent({}, ({ state }) => {
      state.diffs.showTreeList = true;
      state.diffs.isParallelView = false;
    });

    expect(wrapper.contains('.container-limited.limit-container-width')).toBe(false);
  });

  it('does not add container-limiting classes when isFluidLayout', () => {
    createComponent({ isFluidLayout: true }, ({ state }) => {
      state.diffs.isParallelView = false;
    });

    expect(wrapper.contains('.container-limited.limit-container-width')).toBe(false);
  });

  it('displays loading icon on loading', () => {
    createComponent({}, ({ state }) => {
      state.diffs.isLoading = true;
    });

    expect(wrapper.contains(GlLoadingIcon)).toBe(true);
  });

  it('displays loading icon on batch loading', () => {
    createComponent({}, ({ state }) => {
      state.diffs.isBatchLoading = true;
    });

    expect(wrapper.contains(GlLoadingIcon)).toBe(true);
  });

  it('displays diffs container when not loading', () => {
    createComponent();

    expect(wrapper.contains(GlLoadingIcon)).toBe(false);
    expect(wrapper.contains('#diffs')).toBe(true);
  });

  it('does not show commit info', () => {
    createComponent();

    expect(wrapper.contains('.blob-commit-info')).toBe(false);
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

      expect(wrapper.contains(NoChanges)).toBe(true);
    });

    it('does not render empty state when diff files exist', () => {
      createComponent({}, ({ state }) => {
        state.diffs.diffFiles.push({
          id: 1,
        });
      });

      expect(wrapper.contains(NoChanges)).toBe(false);
      expect(wrapper.findAll(DiffFile).length).toBe(1);
    });

    it('does not render empty state when versions match', () => {
      createComponent({}, ({ state }) => {
        state.diffs.startVersion = mergeRequestDiff;
        state.diffs.mergeRequestDiff = mergeRequestDiff;
      });

      expect(wrapper.contains(NoChanges)).toBe(false);
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

      expect(wrapper.contains(CompareVersions)).toBe(true);
      expect(wrapper.find(CompareVersions).props()).toEqual(
        expect.objectContaining({
          mergeRequestDiffs: diffsMockData,
        }),
      );
    });

    it('should render hidden files warning if render overflow warning is present', () => {
      createComponent({}, ({ state }) => {
        state.diffs.renderOverflowWarning = true;
        state.diffs.realSize = '5';
        state.diffs.plainDiffPath = 'plain diff path';
        state.diffs.emailPatchPath = 'email patch path';
        state.diffs.size = 1;
      });

      expect(wrapper.contains(HiddenFilesWarning)).toBe(true);
      expect(wrapper.find(HiddenFilesWarning).props()).toEqual(
        expect.objectContaining({
          total: '5',
          plainDiffPath: 'plain diff path',
          emailPatchPath: 'email patch path',
          visible: 1,
        }),
      );
    });

    it('should display commit widget if store has a commit', () => {
      createComponent({}, () => {
        store.state.diffs.commit = {
          author: 'John Doe',
        };
      });

      expect(wrapper.contains(CommitWidget)).toBe(true);
    });

    it('should display diff file if there are diff files', () => {
      createComponent({}, ({ state }) => {
        state.diffs.diffFiles.push({ sha: '123' });
      });

      expect(wrapper.contains(DiffFile)).toBe(true);
    });

    it('should render tree list', () => {
      createComponent();

      expect(wrapper.find(TreeList).exists()).toBe(true);
    });
  });

  describe('hideTreeListIfJustOneFile', () => {
    let toggleShowTreeList;

    beforeEach(() => {
      toggleShowTreeList = jest.fn();
    });

    afterEach(() => {
      localStorage.removeItem('mr_tree_show');
    });

    it('calls toggleShowTreeList when only 1 file', () => {
      createComponent({}, ({ state }) => {
        state.diffs.diffFiles.push({ sha: '123' });
      });

      wrapper.setMethods({
        toggleShowTreeList,
      });

      wrapper.vm.hideTreeListIfJustOneFile();

      expect(toggleShowTreeList).toHaveBeenCalledWith(false);
    });

    it('does not call toggleShowTreeList when more than 1 file', () => {
      createComponent({}, ({ state }) => {
        state.diffs.diffFiles.push({ sha: '123' });
        state.diffs.diffFiles.push({ sha: '124' });
      });

      wrapper.setMethods({
        toggleShowTreeList,
      });

      wrapper.vm.hideTreeListIfJustOneFile();

      expect(toggleShowTreeList).not.toHaveBeenCalled();
    });

    it('does not call toggleShowTreeList when localStorage is set', () => {
      localStorage.setItem('mr_tree_show', 'true');

      createComponent({}, ({ state }) => {
        state.diffs.diffFiles.push({ sha: '123' });
      });

      wrapper.setMethods({
        toggleShowTreeList,
      });

      wrapper.vm.hideTreeListIfJustOneFile();

      expect(toggleShowTreeList).not.toHaveBeenCalled();
    });
  });
});
