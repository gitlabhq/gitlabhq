import { GlLoadingIcon, GlPagination } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Mousetrap from 'mousetrap';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { TEST_HOST } from 'spec/test_constants';
import App from '~/diffs/components/app.vue';
import CommitWidget from '~/diffs/components/commit_widget.vue';
import CompareVersions from '~/diffs/components/compare_versions.vue';
import DiffFile from '~/diffs/components/diff_file.vue';
import NoChanges from '~/diffs/components/no_changes.vue';
import TreeList from '~/diffs/components/tree_list.vue';

/* eslint-disable import/order */
/* You know what: sometimes alphabetical isn't the best order */
import CollapsedFilesWarning from '~/diffs/components/collapsed_files_warning.vue';
import HiddenFilesWarning from '~/diffs/components/hidden_files_warning.vue';
import MergeConflictWarning from '~/diffs/components/merge_conflict_warning.vue';
/* eslint-enable import/order */

import axios from '~/lib/utils/axios_utils';
import * as urlUtils from '~/lib/utils/url_utility';
import createDiffsStore from '../create_diffs_store';
import diffsMockData from '../mock_data/merge_request_diffs';

const mergeRequestDiff = { version_index: 1 };
const TEST_ENDPOINT = `${TEST_HOST}/diff/endpoint`;
const COMMIT_URL = `${TEST_HOST}/COMMIT/OLD`;
const UPDATED_COMMIT_URL = `${TEST_HOST}/COMMIT/NEW`;

Vue.use(Vuex);

function getCollapsedFilesWarning(wrapper) {
  return wrapper.find(CollapsedFilesWarning);
}

describe('diffs/components/app', () => {
  const oldMrTabs = window.mrTabs;
  let store;
  let wrapper;
  let mock;

  function createComponent(props = {}, extendStore = () => {}, provisions = {}) {
    const provide = {
      ...provisions,
      glFeatures: {
        ...(provisions.glFeatures || {}),
      },
    };

    store = createDiffsStore();
    store.state.diffs.isLoading = false;
    store.state.diffs.isTreeLoaded = true;

    extendStore(store);

    wrapper = shallowMount(App, {
      propsData: {
        endpoint: TEST_ENDPOINT,
        endpointMetadata: `${TEST_HOST}/diff/endpointMetadata`,
        endpointBatch: `${TEST_HOST}/diff/endpointBatch`,
        endpointCoverage: `${TEST_HOST}/diff/endpointCoverage`,
        endpointCodequality: '',
        projectPath: 'namespace/project',
        currentUser: {},
        changesEmptyStateIllustration: '',
        dismissEndpoint: '',
        showSuggestPopover: true,
        fileByFileUserPreference: false,
        ...props,
      },
      provide,
      store,
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
    beforeEach(() => {
      const fetchResolver = () => {
        store.state.diffs.retrievingBatches = false;
        store.state.notes.discussions = 'test';
        return Promise.resolve({ real_size: 100 });
      };
      jest.spyOn(window, 'requestIdleCallback').mockImplementation((fn) => fn());
      createComponent();
      jest.spyOn(wrapper.vm, 'fetchDiffFilesMeta').mockImplementation(fetchResolver);
      jest.spyOn(wrapper.vm, 'fetchDiffFilesBatch').mockImplementation(fetchResolver);
      jest.spyOn(wrapper.vm, 'fetchCoverageFiles').mockImplementation(fetchResolver);
      jest.spyOn(wrapper.vm, 'setDiscussions').mockImplementation(() => {});
      jest.spyOn(wrapper.vm, 'unwatchDiscussions').mockImplementation(() => {});
      jest.spyOn(wrapper.vm, 'unwatchRetrievingBatches').mockImplementation(() => {});
      store.state.diffs.retrievingBatches = true;
      store.state.diffs.diffFiles = [];
      return nextTick();
    });

    it('calls batch methods if diffsBatchLoad is enabled, and not latest version', async () => {
      expect(wrapper.vm.diffFilesLength).toEqual(0);
      wrapper.vm.fetchData(false);

      await nextTick();

      expect(wrapper.vm.fetchDiffFilesMeta).toHaveBeenCalled();
      expect(wrapper.vm.fetchDiffFilesBatch).toHaveBeenCalled();
      expect(wrapper.vm.fetchCoverageFiles).toHaveBeenCalled();
      expect(wrapper.vm.unwatchDiscussions).toHaveBeenCalled();
      expect(wrapper.vm.diffFilesLength).toBe(100);
      expect(wrapper.vm.unwatchRetrievingBatches).toHaveBeenCalled();
    });

    it('calls batch methods if diffsBatchLoad is enabled, and latest version', async () => {
      expect(wrapper.vm.diffFilesLength).toEqual(0);
      wrapper.vm.fetchData(false);

      await nextTick();

      expect(wrapper.vm.fetchDiffFilesMeta).toHaveBeenCalled();
      expect(wrapper.vm.fetchDiffFilesBatch).toHaveBeenCalled();
      expect(wrapper.vm.fetchCoverageFiles).toHaveBeenCalled();
      expect(wrapper.vm.unwatchDiscussions).toHaveBeenCalled();
      expect(wrapper.vm.diffFilesLength).toBe(100);
      expect(wrapper.vm.unwatchRetrievingBatches).toHaveBeenCalled();
    });
  });

  describe('codequality diff', () => {
    it('does not fetch code quality data on FOSS', async () => {
      createComponent();
      jest.spyOn(wrapper.vm, 'fetchCodequality');
      wrapper.vm.fetchData(false);

      expect(wrapper.vm.fetchCodequality).not.toHaveBeenCalled();
    });
  });

  it.each`
    props                      | state                                                              | expected
    ${{ isFluidLayout: true }} | ${{ isParallelView: false }}                                       | ${false}
    ${{}}                      | ${{ isParallelView: false }}                                       | ${true}
    ${{}}                      | ${{ showTreeList: true, diffFiles: [{}], isParallelView: false }}  | ${false}
    ${{}}                      | ${{ showTreeList: false, diffFiles: [{}], isParallelView: false }} | ${true}
    ${{}}                      | ${{ showTreeList: false, diffFiles: [], isParallelView: false }}   | ${true}
  `(
    'uses container-limiting classes ($expected) with state ($state) and props ($props)',
    ({ props, state, expected }) => {
      createComponent(props, ({ state: origState }) => Object.assign(origState.diffs, state));

      expect(wrapper.find('.container-limited.limit-container-width').exists()).toBe(expected);
    },
  );

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

    it('sets highlighted row if hash exists in location object', async () => {
      createComponent({
        shouldShow: true,
      });

      // Component uses $nextTick so we wait until that has finished
      await nextTick();

      expect(store.state.diffs.highlightedRow).toBe('ABC_123');
    });

    it('marks current diff file based on currently highlighted row', async () => {
      createComponent({
        shouldShow: true,
      });

      // Component uses $nextTick so we wait until that has finished
      await nextTick();
      expect(store.state.diffs.currentDiffFileId).toBe('ABC');
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
      createComponent({}, ({ state }) => {
        state.diffs.diffFiles = [{ file_hash: '111', file_path: '111.js' }];
      });

      expect(wrapper.find('.js-diff-tree-list').element.style.width).toEqual('320px');
    });
  });

  it('marks current diff file based on currently highlighted row', async () => {
    createComponent({
      shouldShow: true,
    });

    // Component uses nextTick so we wait until that has finished
    await nextTick();

    expect(store.state.diffs.currentDiffFileId).toBe('ABC');
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
  });

  describe('keyboard shortcut navigation', () => {
    let spies = [];
    let moveSpy;
    let jumpSpy;

    function setup(componentProps) {
      createComponent(componentProps, ({ state }) => {
        state.diffs.commit = { id: 'SHA123' };
      });

      moveSpy = jest.spyOn(wrapper.vm, 'moveToNeighboringCommit').mockImplementation(() => {});
      jumpSpy = jest.spyOn(wrapper.vm, 'jumpToFile').mockImplementation(() => {});
      spies = [jumpSpy, moveSpy];
    }

    describe('visible app', () => {
      it.each`
        key    | name                         | spy  | args
        ${'['} | ${'jumpToFile'}              | ${0} | ${[-1]}
        ${'k'} | ${'jumpToFile'}              | ${0} | ${[-1]}
        ${']'} | ${'jumpToFile'}              | ${0} | ${[+1]}
        ${'j'} | ${'jumpToFile'}              | ${0} | ${[+1]}
        ${'x'} | ${'moveToNeighboringCommit'} | ${1} | ${[{ direction: 'previous' }]}
        ${'c'} | ${'moveToNeighboringCommit'} | ${1} | ${[{ direction: 'next' }]}
      `(
        'calls `$name()` with correct parameters whenever the "$key" key is pressed',
        async ({ key, spy, args }) => {
          setup({ shouldShow: true });

          await nextTick();
          expect(spies[spy]).not.toHaveBeenCalled();

          Mousetrap.trigger(key);

          expect(spies[spy]).toHaveBeenCalledWith(...args);
        },
      );

      it.each`
        key    | name                         | spy  | allowed
        ${'d'} | ${'jumpToFile'}              | ${0} | ${['[', ']', 'j', 'k']}
        ${'r'} | ${'moveToNeighboringCommit'} | ${1} | ${['x', 'c']}
      `(
        `does not call \`$name()\` when a key that is not one of \`$allowed\` is pressed`,
        async ({ key, spy }) => {
          setup({ shouldShow: true });

          await nextTick();
          Mousetrap.trigger(key);

          expect(spies[spy]).not.toHaveBeenCalled();
        },
      );
    });

    describe('hidden app', () => {
      beforeEach(async () => {
        setup({ shouldShow: false });

        await nextTick();
        Mousetrap.reset();
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
      createComponent({}, () => {
        store.state.diffs.diffFiles = [
          { file_hash: '111', file_path: '111.js' },
          { file_hash: '222', file_path: '222.js' },
          { file_hash: '333', file_path: '333.js' },
        ];
      });
      spy = jest.spyOn(store, 'dispatch');
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('jumps to next and previous files in the list', async () => {
      await nextTick();

      wrapper.vm.jumpToFile(+1);

      expect(spy.mock.calls[spy.mock.calls.length - 1]).toEqual(['diffs/scrollToFile', '222.js']);
      store.state.diffs.currentDiffFileId = '222';
      wrapper.vm.jumpToFile(+1);

      expect(spy.mock.calls[spy.mock.calls.length - 1]).toEqual(['diffs/scrollToFile', '333.js']);
      store.state.diffs.currentDiffFileId = '333';
      wrapper.vm.jumpToFile(-1);

      expect(spy.mock.calls[spy.mock.calls.length - 1]).toEqual(['diffs/scrollToFile', '222.js']);
    });

    it('does not jump to previous file from the first one', async () => {
      await nextTick();
      store.state.diffs.currentDiffFileId = '333';

      expect(wrapper.vm.currentDiffIndex).toBe(2);

      wrapper.vm.jumpToFile(+1);

      expect(wrapper.vm.currentDiffIndex).toBe(2);
      expect(spy).not.toHaveBeenCalled();
    });

    it('does not jump to next file from the last one', async () => {
      await nextTick();
      expect(wrapper.vm.currentDiffIndex).toBe(0);

      wrapper.vm.jumpToFile(-1);

      expect(wrapper.vm.currentDiffIndex).toBe(0);
      expect(spy).not.toHaveBeenCalled();
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

    it('when the commit changes and the app is not loading it should update the history, refetch the diff data, and update the view', async () => {
      createComponent({}, ({ state }) => {
        state.diffs.commit = { ...state.diffs.commit, id: 'OLD' };
      });
      spy();

      store.state.diffs.commit = { id: 'NEW' };

      await nextTick();
      expect(urlUtils.updateHistory).toHaveBeenCalledWith({
        title: document.title,
        url: UPDATED_COMMIT_URL,
      });
      expect(wrapper.vm.refetchDiffData).toHaveBeenCalled();
      expect(wrapper.vm.adjustView).toHaveBeenCalled();
    });

    it.each`
      isLoading | oldSha   | newSha
      ${true}   | ${'OLD'} | ${'NEW'}
      ${false}  | ${'NEW'} | ${'NEW'}
    `(
      'given `{ "isLoading": $isLoading, "oldSha": "$oldSha", "newSha": "$newSha" }`, nothing should happen',
      async ({ isLoading, oldSha, newSha }) => {
        createComponent({}, ({ state }) => {
          state.diffs.isLoading = isLoading;
          state.diffs.commit = { ...state.diffs.commit, id: oldSha };
        });
        spy();

        store.state.diffs.commit = { id: newSha };

        await nextTick();
        expect(urlUtils.updateHistory).not.toHaveBeenCalled();
        expect(wrapper.vm.refetchDiffData).not.toHaveBeenCalled();
        expect(wrapper.vm.adjustView).not.toHaveBeenCalled();
      },
    );
  });

  describe('diffs', () => {
    it('should render compare versions component', () => {
      createComponent({}, ({ state }) => {
        state.diffs.diffFiles = [{ file_hash: '111', file_path: '111.js' }];
        state.diffs.mergeRequestDiffs = diffsMockData;
        state.diffs.targetBranchName = 'target-branch';
        state.diffs.mergeRequestDiff = mergeRequestDiff;
      });

      expect(wrapper.find(CompareVersions).exists()).toBe(true);
      expect(wrapper.find(CompareVersions).props()).toEqual(
        expect.objectContaining({
          isLimitedContainer: false,
          diffFilesCountText: null,
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

      describe('merge conflicts', () => {
        it('should render the merge conflicts banner if viewing the whole changeset and there are conflicts', () => {
          createComponent({}, ({ state }) => {
            Object.assign(state.diffs, {
              latestDiff: true,
              startVersion: null,
              hasConflicts: true,
              canMerge: false,
              conflictResolutionPath: 'path',
            });
          });

          expect(wrapper.find(MergeConflictWarning).exists()).toBe(true);
        });

        it.each`
          prop              | value
          ${'latestDiff'}   | ${false}
          ${'startVersion'} | ${'notnull'}
          ${'hasConflicts'} | ${false}
        `(
          "should not render if any of the MR properties aren't correct - like $prop: $value",
          ({ prop, value }) => {
            createComponent({}, ({ state }) => {
              Object.assign(state.diffs, {
                latestDiff: true,
                startVersion: null,
                hasConflicts: true,
                [prop]: value,
              });
            });

            expect(wrapper.find(MergeConflictWarning).exists()).toBe(false);
          },
        );
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

    it("doesn't render tree list when no changes exist", () => {
      createComponent();

      expect(wrapper.find(TreeList).exists()).toBe(false);
    });

    it('should render tree list', () => {
      createComponent({}, ({ state }) => {
        state.diffs.diffFiles = [{ file_hash: '111', file_path: '111.js' }];
      });

      expect(wrapper.find(TreeList).exists()).toBe(true);
    });
  });

  describe('setTreeDisplay', () => {
    afterEach(() => {
      localStorage.removeItem('mr_tree_show');
    });

    it('calls setShowTreeList when only 1 file', () => {
      createComponent({}, ({ state }) => {
        state.diffs.diffFiles.push({ sha: '123' });
      });
      jest.spyOn(store, 'dispatch');
      wrapper.vm.setTreeDisplay();

      expect(store.dispatch).toHaveBeenCalledWith('diffs/setShowTreeList', {
        showTreeList: false,
        saving: false,
      });
    });

    it('calls setShowTreeList with true when more than 1 file is in diffs array', () => {
      createComponent({}, ({ state }) => {
        state.diffs.diffFiles.push({ sha: '123' });
        state.diffs.diffFiles.push({ sha: '124' });
      });
      jest.spyOn(store, 'dispatch');

      wrapper.vm.setTreeDisplay();

      expect(store.dispatch).toHaveBeenCalledWith('diffs/setShowTreeList', {
        showTreeList: true,
        saving: false,
      });
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
      jest.spyOn(store, 'dispatch');

      wrapper.vm.setTreeDisplay();

      expect(store.dispatch).toHaveBeenCalledWith('diffs/setShowTreeList', {
        showTreeList,
        saving: false,
      });
    });
  });

  describe('file-by-file', () => {
    it('renders a single diff', async () => {
      createComponent({ fileByFileUserPreference: true }, ({ state }) => {
        state.diffs.diffFiles.push({ file_hash: '123' });
        state.diffs.diffFiles.push({ file_hash: '312' });
      });

      await nextTick();

      expect(wrapper.findAll(DiffFile).length).toBe(1);
    });

    describe('pagination', () => {
      const fileByFileNav = () => wrapper.find('[data-testid="file-by-file-navigation"]');
      const paginator = () => fileByFileNav().find(GlPagination);

      it('sets previous button as disabled', async () => {
        createComponent({ fileByFileUserPreference: true }, ({ state }) => {
          state.diffs.diffFiles.push({ file_hash: '123' }, { file_hash: '312' });
        });

        await nextTick();

        expect(paginator().attributes('prevpage')).toBe(undefined);
        expect(paginator().attributes('nextpage')).toBe('2');
      });

      it('sets next button as disabled', async () => {
        createComponent({ fileByFileUserPreference: true }, ({ state }) => {
          state.diffs.diffFiles.push({ file_hash: '123' }, { file_hash: '312' });
          state.diffs.currentDiffFileId = '312';
        });

        await nextTick();

        expect(paginator().attributes('prevpage')).toBe('1');
        expect(paginator().attributes('nextpage')).toBe(undefined);
      });

      it("doesn't display when there's fewer than 2 files", async () => {
        createComponent({ fileByFileUserPreference: true }, ({ state }) => {
          state.diffs.diffFiles.push({ file_hash: '123' });
          state.diffs.currentDiffFileId = '123';
        });

        await nextTick();

        expect(fileByFileNav().exists()).toBe(false);
      });

      it.each`
        currentDiffFileId | targetFile
        ${'123'}          | ${2}
        ${'312'}          | ${1}
      `(
        'it calls navigateToDiffFileIndex with $index when $link is clicked',
        async ({ currentDiffFileId, targetFile }) => {
          createComponent({ fileByFileUserPreference: true }, ({ state }) => {
            state.diffs.diffFiles.push({ file_hash: '123' }, { file_hash: '312' });
            state.diffs.currentDiffFileId = currentDiffFileId;
          });

          await nextTick();

          jest.spyOn(wrapper.vm, 'navigateToDiffFileIndex');

          paginator().vm.$emit('input', targetFile);

          await nextTick();

          expect(wrapper.vm.navigateToDiffFileIndex).toHaveBeenCalledWith(targetFile - 1);
        },
      );
    });
  });

  describe('diff file tree is aware of review bar', () => {
    it('it does not have review-bar-visible class when review bar is not visible', () => {
      createComponent({}, ({ state }) => {
        state.diffs.diffFiles = [{ file_hash: '111', file_path: '111.js' }];
      });

      expect(wrapper.find('.js-diff-tree-list').exists()).toBe(true);
      expect(wrapper.find('.js-diff-tree-list.review-bar-visible').exists()).toBe(false);
    });

    it('it does have review-bar-visible class when review bar is visible', () => {
      createComponent({}, ({ state }) => {
        state.diffs.diffFiles = [{ file_hash: '111', file_path: '111.js' }];
        state.batchComments.drafts = ['draft message'];
      });

      expect(wrapper.find('.js-diff-tree-list.review-bar-visible').exists()).toBe(true);
    });
  });
});
