import { GlLoadingIcon, GlPagination } from '@gitlab/ui';
import { createWrapper, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import getMRCodequalityAndSecurityReports from 'ee_else_ce/diffs/components/graphql/get_mr_codequality_and_security_reports.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { mockTracking } from 'helpers/tracking_helper';
import { TEST_HOST } from 'spec/test_constants';

import App from '~/diffs/components/app.vue';
import CommitWidget from '~/diffs/components/commit_widget.vue';
import CompareVersions from '~/diffs/components/compare_versions.vue';
import DiffFile from '~/diffs/components/diff_file.vue';
import NoChanges from '~/diffs/components/no_changes.vue';
import FindingsDrawer from 'ee_component/diffs/components/shared/findings_drawer.vue';
import DiffsFileTree from '~/diffs/components/diffs_file_tree.vue';
import DiffAppControls from '~/diffs/components/diff_app_controls.vue';

import CollapsedFilesWarning from '~/diffs/components/collapsed_files_warning.vue';
import HiddenFilesWarning from '~/diffs/components/hidden_files_warning.vue';

import eventHub from '~/diffs/event_hub';
import notesEventHub from '~/notes/event_hub';
import { EVT_DISCUSSIONS_ASSIGNED, FILE_BROWSER_VISIBLE } from '~/diffs/constants';

import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { Mousetrap } from '~/lib/mousetrap';
import * as urlUtils from '~/lib/utils/url_utility';
import * as commonUtils from '~/lib/utils/common_utils';
import { BV_HIDE_TOOLTIP, DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { stubPerformanceWebAPI } from 'helpers/performance';
import { getDiffFileMock } from 'jest/diffs/mock_data/diff_file';
import waitForPromises from 'helpers/wait_for_promises';
import { removeCookie, setCookie } from '~/lib/utils/common_utils';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { DynamicScroller } from 'vendor/vue-virtual-scroller';
import * as mergeRequestUtils from '~/diffs/utils/merge_request';
import {
  keysFor,
  MR_NEXT_FILE_IN_DIFF,
  MR_PREVIOUS_FILE_IN_DIFF,
} from '~/behaviors/shortcuts/keybindings';
import createDiffsStore from '../create_diffs_store';
import diffsMockData from '../mock_data/merge_request_diffs';

const TEST_ENDPOINT = `${TEST_HOST}/diff/endpoint`;
const COMMIT_URL = `${TEST_HOST}/COMMIT/OLD`;
const UPDATED_COMMIT_URL = `${TEST_HOST}/COMMIT/NEW`;
const ENDPOINT_BATCH_URL = `${TEST_HOST}/diff/endpointBatch`;
const ENDPOINT_METADATA_URL = `${TEST_HOST}/diff/endpointMetadata`;

Vue.use(Vuex);
Vue.use(VueApollo);
Vue.use(PiniaVuePlugin);

function getCollapsedFilesWarning(wrapper) {
  return wrapper.findComponent(CollapsedFilesWarning);
}

describe('diffs/components/app', () => {
  const oldMrTabs = window.mrTabs;
  let store;
  let wrapper;
  let mock;
  let fakeApollo;
  let pinia;

  const codeQualityAndSastQueryHandlerSuccess = jest.fn().mockResolvedValue({});

  const createComponent = ({ props = {}, provisions = {} } = {}) => {
    fakeApollo = createMockApollo([
      [getMRCodequalityAndSecurityReports, codeQualityAndSastQueryHandlerSuccess],
    ]);

    const provide = {
      ...provisions,
      glFeatures: {
        ...provisions.glFeatures,
      },
    };

    wrapper = shallowMount(App, {
      apolloProvider: fakeApollo,
      propsData: {
        shouldShow: true,
        endpointCoverage: `${TEST_HOST}/diff/endpointCoverage`,
        endpointCodequality: '',
        sastReportAvailable: false,
        projectPath: 'namespace/project',
        currentUser: {},
        changesEmptyStateIllustration: '',
        ...props,
      },
      provide,
      store: createDiffsStore(),
      pinia,
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });

    store = useLegacyDiffs();
    store.isLoading = false;
    store.isTreeLoaded = true;

    store.setBaseConfig({
      endpoint: TEST_ENDPOINT,
      endpointMetadata: ENDPOINT_METADATA_URL,
      endpointBatch: ENDPOINT_BATCH_URL,
      endpointDiffForPath: TEST_ENDPOINT,
      projectPath: 'namespace/project',
      dismissEndpoint: '',
      showSuggestPopover: true,
      mrReviews: {},
      diffViewType: 'inline',
      viewDiffsFileByFile: false,
    });

    store.fetchDiffFilesMeta.mockResolvedValue({ real_size: '20' });
    store.fetchDiffFilesBatch.mockResolvedValue();
    store.assignDiscussionsToDiff.mockResolvedValue();

    stubPerformanceWebAPI();
    // setup globals (needed for component to mount :/)
    window.mrTabs = {
      resetViewContainer: jest.fn(),
    };
    window.mrTabs.expandViewContainer = jest.fn();
    mock = new MockAdapter(axios);
    mock.onGet(TEST_ENDPOINT).reply(HTTP_STATUS_OK, {});
  });

  afterEach(() => {
    // reset globals
    window.mrTabs = oldMrTabs;

    mock.restore();
  });

  describe('fetch diff methods', () => {
    it('calls batch methods if diffsBatchLoad is enabled', () => {
      jest.spyOn(window, 'requestIdleCallback').mockImplementation((fn) => fn());
      createComponent({});

      expect(store.fetchDiffFilesMeta).toHaveBeenCalled();
      expect(store.fetchDiffFilesBatch).toHaveBeenCalledWith(false);
      expect(store.fetchCoverageFiles).toHaveBeenCalled();
    });

    it('updates diff counter', async () => {
      const spy = jest.spyOn(mergeRequestUtils, 'updateChangesTabCount');
      createComponent();
      await waitForPromises();
      expect(spy).toHaveBeenCalledWith({ count: 20 });
    });

    it('sets diff counter to 0 without changes', async () => {
      const spy = jest.spyOn(mergeRequestUtils, 'updateChangesTabCount');
      store.fetchDiffFilesMeta.mockResolvedValue();
      createComponent();
      await waitForPromises();
      expect(spy).toHaveBeenCalledWith({ count: 0 });
    });
  });

  describe('codequality diff', () => {
    it('does not fetch code quality data on FOSS', () => {
      createComponent({});
      expect(codeQualityAndSastQueryHandlerSuccess).not.toHaveBeenCalled();
    });
  });

  describe('SAST diff', () => {
    it('does not fetch Sast data on FOSS', () => {
      createComponent({});
      expect(codeQualityAndSastQueryHandlerSuccess).not.toHaveBeenCalled();
    });
  });

  it('displays loading icon on loading', async () => {
    createComponent();
    store.isLoading = true;
    await nextTick();

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('displays loading icon on batch loading', async () => {
    createComponent();
    store.batchLoadingState = 'loading';
    await nextTick();

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('displays diffs container when not loading', () => {
    createComponent({});

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
    expect(wrapper.find('#diffs').exists()).toBe(true);
  });

  describe('row highlighting', () => {
    beforeEach(() => {
      window.location.hash = 'ABC_123';
    });

    it('sets highlighted row if hash exists in location object', () => {
      createComponent();
      expect(store.setHighlightedRow).toHaveBeenCalledWith({ lineCode: 'ABC_123' });
    });

    it('renders findings-drawer', () => {
      createComponent({});
      expect(wrapper.findComponent(FindingsDrawer).exists()).toBe(true);
    });
  });

  describe('empty state', () => {
    it('renders empty state when no diff files exist', () => {
      createComponent();

      expect(wrapper.findComponent(NoChanges).exists()).toBe(true);
    });

    it('does not render empty state when diff files exist', async () => {
      createComponent();
      store.diffFiles = [{ id: 1 }];
      store.treeEntries = { 1: { type: 'blob', id: 1 } };

      await nextTick();

      expect(wrapper.findComponent(NoChanges).exists()).toBe(false);
      expect(wrapper.findComponent(DynamicScroller).props('items')).toStrictEqual(store.diffFiles);
    });
  });

  describe('keyboard shortcut navigation', () => {
    let spies = [];
    let moveSpy;
    let jumpSpy;

    function setup(componentProps) {
      createComponent({
        props: componentProps,
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
    const nextFile = () => Mousetrap.trigger(keysFor(MR_NEXT_FILE_IN_DIFF)[0]);
    const prevFile = () => Mousetrap.trigger(keysFor(MR_PREVIOUS_FILE_IN_DIFF)[0]);

    beforeEach(() => {
      store.treeEntries = [
        { type: 'blob', fileHash: '111', path: '111.js' },
        { type: 'blob', fileHash: '222', path: '222.js' },
        { type: 'blob', fileHash: '333', path: '333.js' },
      ];
      createComponent();
    });

    it('jumps to next and previous files in the list', () => {
      nextFile();

      expect(store.goToFile).toHaveBeenNthCalledWith(1, { path: '222.js' });
      store.currentDiffFileId = '222';

      nextFile();

      expect(store.goToFile).toHaveBeenNthCalledWith(2, { path: '333.js' });
      store.currentDiffFileId = '333';

      prevFile();

      expect(store.goToFile).toHaveBeenNthCalledWith(3, { path: '222.js' });
    });

    it('does not jump to previous file from the first one', () => {
      store.currentDiffFileId = '333';
      nextFile();
      expect(store.goToFile).not.toHaveBeenCalled();
    });

    it('does not jump to next file from the last one', () => {
      prevFile();
      expect(store.goToFile).not.toHaveBeenCalled();
    });
  });

  describe('commit watcher', () => {
    beforeEach(() => {
      setWindowLocation(COMMIT_URL);
      document.title = 'My Title';
    });

    beforeEach(() => {
      jest.spyOn(urlUtils, 'updateHistory');
    });

    it('when the commit changes and the app is not loading it should update the history, refetch the diff data, and update the view', async () => {
      store.commit = { ...store.commit, id: 'OLD' };
      createComponent();
      expect(store.fetchDiffFilesMeta).toHaveBeenCalledTimes(1);
      store.commit = { id: 'NEW' };
      await nextTick();
      expect(urlUtils.updateHistory).toHaveBeenCalledWith({
        title: document.title,
        url: UPDATED_COMMIT_URL,
      });
      expect(store.fetchDiffFilesMeta).toHaveBeenCalledTimes(2);
    });

    it.each`
      isLoading | oldSha   | newSha
      ${true}   | ${'OLD'} | ${'NEW'}
      ${false}  | ${'NEW'} | ${'NEW'}
    `(
      'given `{ "isLoading": $isLoading, "oldSha": "$oldSha", "newSha": "$newSha" }`, nothing should happen',
      async ({ isLoading, oldSha, newSha }) => {
        store.isLoading = isLoading;
        store.commit = { ...store.commit, id: oldSha };
        createComponent();
        expect(store.fetchDiffFilesMeta).toHaveBeenCalledTimes(1);
        store.commit = { id: newSha };
        await nextTick();
        expect(urlUtils.updateHistory).not.toHaveBeenCalled();
        expect(store.fetchDiffFilesMeta).toHaveBeenCalledTimes(1);
      },
    );
  });

  describe('diffs', () => {
    it('should render compare versions component', () => {
      createComponent();
      expect(wrapper.findComponent(CompareVersions).exists()).toBe(true);
      expect(wrapper.findComponent(CompareVersions).props()).toMatchObject({
        toggleFileTreeVisible: false,
      });
    });

    it('should render file tree toggle in compare versions', () => {
      store.diffFiles = [getDiffFileMock()];
      createComponent();

      expect(wrapper.findComponent(CompareVersions).props()).toMatchObject({
        toggleFileTreeVisible: true,
      });
    });

    it('should render app controls component', () => {
      store.diffFiles = diffsMockData;
      store.realSize = '10';
      store.addedLines = 15;
      store.removedLines = 20;
      createComponent();

      expect(wrapper.findComponent(DiffAppControls).exists()).toBe(true);
      expect(wrapper.findComponent(DiffAppControls).props()).toEqual(
        expect.objectContaining({
          hasChanges: true,
          diffsCount: '10',
          addedLines: 15,
          removedLines: 20,
          showWhitespace: true,
          viewDiffsFileByFile: false,
          diffViewType: 'inline',
        }),
      );
    });

    it('collapses all files', async () => {
      createComponent();
      await wrapper.findComponent(DiffAppControls).vm.$emit('collapseAllFiles');
      expect(store.collapseAllFiles).toHaveBeenCalled();
    });

    it('expands all files', async () => {
      createComponent();
      await wrapper.findComponent(DiffAppControls).vm.$emit('expandAllFiles');
      expect(store.expandAllFiles).toHaveBeenCalled();
    });

    it('switches whitespace mode', async () => {
      createComponent();
      await wrapper.findComponent(DiffAppControls).vm.$emit('toggleWhitespace', false);
      expect(store.setShowWhitespace).toHaveBeenCalledWith({ showWhitespace: false });
    });

    it('switches view mode', async () => {
      createComponent();
      await wrapper.findComponent(DiffAppControls).vm.$emit('updateDiffViewType', 'parallel');
      expect(store.setDiffViewType).toHaveBeenCalledWith('parallel');
    });

    it('enables file by file mode', async () => {
      createComponent();
      await wrapper.findComponent(DiffAppControls).vm.$emit('toggleFileByFile');
      expect(store.setFileByFile).toHaveBeenCalledWith({ fileByFile: true });
    });

    describe('warnings', () => {
      describe('hidden files', () => {
        it('should render hidden files warning if render overflow warning is present', () => {
          store.renderOverflowWarning = true;
          store.realSize = '5';
          store.plainDiffPath = 'plain diff path';
          store.emailPatchPath = 'email patch path';
          store.size = 1;
          store.treeEntries = {
            111: { type: 'blob', fileHash: '111', path: '111.js' },
          };
          createComponent();

          expect(wrapper.findComponent(HiddenFilesWarning).exists()).toBe(true);
          expect(wrapper.findComponent(HiddenFilesWarning).props()).toEqual(
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
          store.diffFiles = [{ viewer: { automaticallyCollapsed: true } }];
          createComponent();
          expect(getCollapsedFilesWarning(wrapper).exists()).toBe(true);
        });

        it('should not render the collapsed files warning if there are no automatically collapsed files', () => {
          store.diffFiles = [
            { viewer: { automaticallyCollapsed: false, manuallyCollapsed: true } },
            { viewer: { automaticallyCollapsed: false, manuallyCollapsed: false } },
          ];
          createComponent();

          expect(getCollapsedFilesWarning(wrapper).exists()).toBe(false);
        });
      });
    });

    it('should display commit widget if store has a commit', () => {
      store.commit = { author: 'John Doe' };
      createComponent();
      expect(wrapper.findComponent(CommitWidget).exists()).toBe(true);
    });

    it('should display diff file if there are diff files', () => {
      store.diffFiles = [{ file_hash: '111', file_path: '111.js' }];
      store.treeEntries = {
        111: { type: 'blob', fileHash: '111', path: '111.js' },
        123: { type: 'blob', fileHash: '123', path: '123.js' },
        312: { type: 'blob', fileHash: '312', path: '312.js' },
      };
      createComponent();

      expect(wrapper.findComponent(DynamicScroller).exists()).toBe(true);
      expect(wrapper.findComponent(DynamicScroller).props('items')).toStrictEqual(store.diffFiles);
    });

    describe('File browser', () => {
      it('should render file browser when files are present', () => {
        store.realSize = '20';
        store.treeEntries = { 111: { type: 'blob', fileHash: '111', path: '111.js' } };
        createComponent();
        expect(wrapper.findComponent(DiffsFileTree).exists()).toBe(true);
        expect(wrapper.findComponent(DiffsFileTree).props('totalFilesCount')).toBe('20');
      });

      it('should not render file browser without files', async () => {
        createComponent();
        await nextTick();
        expect(wrapper.findComponent(DiffsFileTree).exists()).toBe(false);
      });

      it('should handle clickFile events', () => {
        const file = { path: '111.js' };
        store.treeEntries = { 111: { type: 'blob', fileHash: '111', path: '111.js' } };
        createComponent();
        wrapper.findComponent(DiffsFileTree).vm.$emit('clickFile', file);
        expect(store.goToFile).toHaveBeenCalledWith({ path: file.path });
      });
    });
  });

  describe('file browser visibility', () => {
    beforeEach(() => {
      removeCookie(FILE_BROWSER_VISIBLE);
    });

    it('hides files browser with only 1 file', async () => {
      store.treeEntries = { 123: { type: 'blob', fileHash: '123' } };
      createComponent();
      await waitForPromises();
      expect(useFileBrowser().setFileBrowserVisibility).toHaveBeenCalledWith(false);
    });

    it('shows file browser with more than 1 file', async () => {
      store.treeEntries = {
        111: { type: 'blob', fileHash: '111', path: '111.js' },
        123: { type: 'blob', fileHash: '123', path: '123.js' },
      };
      createComponent();
      await waitForPromises();
      expect(useFileBrowser().setFileBrowserVisibility).toHaveBeenCalledWith(true);
    });

    it.each`
      fileBrowserVisible
      ${true}
      ${false}
    `(
      'sets browser visibility from cookie value: $fileBrowserVisible',
      async ({ fileBrowserVisible }) => {
        setCookie(FILE_BROWSER_VISIBLE, fileBrowserVisible);
        store.treeEntries['123'] = { sha: '123' };
        createComponent();
        await waitForPromises();

        expect(useFileBrowser().setFileBrowserVisibility).toHaveBeenCalledWith(fileBrowserVisible);
      },
    );
  });

  describe('file-by-file', () => {
    let hashSpy;

    beforeEach(() => {
      hashSpy = jest.spyOn(commonUtils, 'handleLocationHash');
    });

    it('renders a single diff', async () => {
      store.treeEntries = {
        123: { type: 'blob', fileHash: '123' },
        312: { type: 'blob', fileHash: '312' },
      };
      store.diffFiles.push({ file_hash: '312' });
      store.viewDiffsFileByFile = true;
      createComponent();

      await nextTick();

      expect(wrapper.findAllComponents(DiffFile).length).toBe(1);
    });

    describe('rechecking the url hash for scrolling', () => {
      const advanceAndCheckCalls = (count = 0) => {
        jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
        expect(hashSpy).toHaveBeenCalledTimes(count);
      };

      it('re-checks one time after the file finishes loading', () => {
        store.diffFiles = [{ isLoadingFullFile: true }];
        store.viewDiffsFileByFile = true;
        createComponent();

        // The hash check is not called if the file is still marked as loading
        expect(hashSpy).toHaveBeenCalledTimes(0);
        eventHub.$emit(EVT_DISCUSSIONS_ASSIGNED);
        advanceAndCheckCalls();
        eventHub.$emit(EVT_DISCUSSIONS_ASSIGNED);
        advanceAndCheckCalls();
        // Once the file has finished loading, it calls through to check the hash
        store.diffFiles[0].isLoadingFullFile = false;
        eventHub.$emit(EVT_DISCUSSIONS_ASSIGNED);
        advanceAndCheckCalls(1);
        // No further scrolls happen after one hash check / scroll
        eventHub.$emit(EVT_DISCUSSIONS_ASSIGNED);
        advanceAndCheckCalls(1);
        eventHub.$emit(EVT_DISCUSSIONS_ASSIGNED);
        advanceAndCheckCalls(1);
      });

      it('does not re-check when not in single-file mode', () => {
        createComponent();

        eventHub.$emit(EVT_DISCUSSIONS_ASSIGNED);

        expect(hashSpy).not.toHaveBeenCalled();
      });
    });

    describe('pagination', () => {
      const fileByFileNav = () => wrapper.find('[data-testid="file-by-file-navigation"]');
      const paginator = () => fileByFileNav().findComponent(GlPagination);

      it('sets previous button as disabled', async () => {
        store.treeEntries = {
          123: { type: 'blob', fileHash: '123' },
          312: { type: 'blob', fileHash: '312' },
        };
        store.viewDiffsFileByFile = true;
        createComponent();

        await nextTick();

        expect(paginator().attributes('prevpage')).toBe(undefined);
        expect(paginator().attributes('nextpage')).toBe('2');
      });

      it('sets next button as disabled', async () => {
        store.treeEntries = {
          123: { type: 'blob', fileHash: '123' },
          312: { type: 'blob', fileHash: '312' },
        };
        store.currentDiffFileId = '312';
        store.viewDiffsFileByFile = true;
        createComponent();

        await nextTick();

        expect(paginator().attributes('prevpage')).toBe('1');
        expect(paginator().attributes('nextpage')).toBe(undefined);
      });

      it("doesn't display when there's fewer than 2 files", async () => {
        store.treeEntries = { 123: { type: 'blob', fileHash: '123' } };
        store.currentDiffFileId = '123';
        store.viewDiffsFileByFile = true;
        createComponent();

        await nextTick();

        expect(fileByFileNav().exists()).toBe(false);
      });

      it.each`
        currentDiffFileId | targetFile
        ${'123'}          | ${2}
        ${'312'}          | ${1}
      `(
        'calls navigateToDiffFileIndex with $index when $link is clicked',
        async ({ currentDiffFileId, targetFile }) => {
          store.treeEntries = {
            123: { type: 'blob', fileHash: '123', filePaths: { old: '1234', new: '123' } },
            312: { type: 'blob', fileHash: '312', filePaths: { old: '3124', new: '312' } },
          };
          store.currentDiffFileId = currentDiffFileId;
          store.viewDiffsFileByFile = true;
          createComponent();

          await nextTick();
          paginator().vm.$emit('input', targetFile);
          await nextTick();
          expect(store.navigateToDiffFileIndex).toHaveBeenLastCalledWith(targetFile - 1);
        },
      );
    });

    describe('non-UI navigation', () => {
      describe('in single-file review mode', () => {
        beforeEach(() => {
          window.location.hash = '123';
          store.treeEntries = {
            123: {
              type: 'blob',
              fileHash: '123',
              filePaths: { old: '1234', new: '123' },
              parentPath: '/',
            },
            312: {
              type: 'blob',
              fileHash: '312',
              filePaths: { old: '3124', new: '312' },
              parentPath: '/',
            },
          };
          store.diffFiles = [{ file_hash: '123' }, { file_hash: '312' }];
          store.viewDiffsFileByFile = true;
          createComponent();
        });

        it.each`
          hash     | updated  | alias
          ${'312'} | ${'312'} | ${'312'}
          ${''}    | ${'123'} | ${'(nothing)'}
        `(
          'reacts to the hash changing to "$alias" externally (e.g. browser back/forward)',
          async ({ hash, updated }) => {
            window.location.hash = hash;
            window.dispatchEvent(new Event('hashchange'));

            await nextTick();

            expect(store.setCurrentFileHash).toHaveBeenCalledWith(updated);
            expect(store.fetchFileByFile).toHaveBeenCalled();
          },
        );
      });

      describe('in "normal" (multi-file) mode', () => {
        beforeEach(() => {
          window.location.hash = '123';
          store.treeEntries = {
            123: {
              type: 'blob',
              fileHash: '123',
              filePaths: { old: '1234', new: '123' },
              parentPath: '/',
            },
            312: {
              type: 'blob',
              fileHash: '312',
              filePaths: { old: '3124', new: '312' },
              parentPath: '/',
            },
          };
          store.diffFiles = [{ file_hash: '123' }, { file_hash: '312' }];
          createComponent();
        });

        it('does not react to the hash changing when in regular (multi-file) mode', async () => {
          window.location.hash = '312';
          window.dispatchEvent(new Event('hashchange'));

          await nextTick();

          expect(store.setCurrentFileHash).not.toHaveBeenCalled();
          expect(store.fetchFileByFile).not.toHaveBeenCalled();
        });
      });
    });
  });

  describe('autoscroll', () => {
    beforeEach(() => {
      store.loadCollapsedDiff.mockResolvedValue();
      store.diffFiles = [
        {
          file_hash: '1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a',
          highlighted_diff_lines: [],
          viewer: { manuallyCollapsed: true },
        },
      ];
      createComponent();
    });

    it('does nothing if the location hash does not include a file hash', () => {
      window.location.hash = 'not_a_file_hash';
      eventHub.$emit('doneLoadingBatches');
      expect(store.loadCollapsedDiff).not.toHaveBeenCalled();
    });

    it('requests that the correct file be loaded', () => {
      store.mergeRequestDiff = {};
      window.location.hash = '1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_0_1';
      expect(store.loadCollapsedDiff).toHaveBeenCalledTimes(0);
      eventHub.$emit('doneLoadingBatches');
      expect(store.loadCollapsedDiff).toHaveBeenCalledTimes(1);
      expect(store.loadCollapsedDiff).toHaveBeenLastCalledWith({
        file: store.diffFiles[0],
      });
    });

    it('does nothing when file is not collapsed', () => {
      store.diffFiles[0].viewer.manuallyCollapsed = false;
      window.location.hash = '1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_0_1';
      eventHub.$emit('doneLoadingBatches');
      expect(store.loadCollapsedDiff).not.toHaveBeenCalled();
    });
  });

  describe('linked file', () => {
    const linkedFileUrl = 'http://localhost.test/linked-file';

    beforeEach(() => {
      store.treeEntries = { 1: { type: 'blob', id: 1 } };
      store.fetchLinkedFile.mockResolvedValue();
    });

    it('fetches and displays the file', async () => {
      const linkedFile = getDiffFileMock();
      store.diffFiles = [linkedFile];
      store.linkedFilehash = linkedFile.file_hash;
      createComponent({ props: { linkedFileUrl } });
      await waitForPromises();

      expect(wrapper.findComponent(DynamicScroller).props('items')[0].file_hash).toBe(
        linkedFile.file_hash,
      );
    });

    it('shows a spinner during loading', async () => {
      let res;
      store.fetchLinkedFile.mockImplementation(
        () =>
          new Promise((resolve) => {
            res = resolve;
          }),
      );
      createComponent({ props: { linkedFileUrl } });
      await nextTick();
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      res();
    });
  });

  describe('draft comments', () => {
    let trackingSpy;

    beforeEach(() => {
      trackingSpy = mockTracking(undefined, window.document, jest.spyOn);
    });

    describe('when adding a new comment to an existing review', () => {
      it('sends the correct tracking event', () => {
        createComponent();
        notesEventHub.$emit('noteFormAddToReview', { name: 'noteFormAddToReview' });

        expect(trackingSpy).toHaveBeenCalledWith(
          undefined,
          'merge_request_click_add_to_review_on_changes_tab',
          expect.any(Object),
        );
      });
    });

    describe('when adding a comment to a new review', () => {
      it('sends the correct tracking event', () => {
        createComponent();
        notesEventHub.$emit('noteFormStartReview', { name: 'noteFormStartReview' });

        expect(trackingSpy).toHaveBeenCalledWith(
          undefined,
          'merge_request_click_start_review_on_changes_tab',
          expect.any(Object),
        );
      });
    });
  });

  describe('tooltips', () => {
    const scroll = () => {
      const scrollEvent = document.createEvent('Event');
      scrollEvent.initEvent('scroll', true, true, window, 1);
      window.dispatchEvent(scrollEvent);
    };

    it('hides tooltips on scroll', () => {
      createComponent();
      const rootWrapper = createWrapper(wrapper.vm.$root);
      scroll();
      expect(rootWrapper.emitted(BV_HIDE_TOOLTIP)).toStrictEqual([[]]);
    });

    it('does not hide tooltips on scroll when invisible', () => {
      createComponent({ props: { shouldShow: false } });
      const rootWrapper = createWrapper(wrapper.vm.$root);
      scroll();
      expect(rootWrapper.emitted(BV_HIDE_TOOLTIP)).toStrictEqual(undefined);
    });
  });

  describe('event tracking', () => {
    let mockGetTime;

    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(() => {
      jest.clearAllMocks();
      mockGetTime = jest.spyOn(Date.prototype, 'getTime');
    });

    afterEach(() => {
      mockGetTime.mockRestore();
    });

    const simulateKeydown = async (key, time) => {
      await nextTick();

      mockGetTime.mockReturnValue(time);
      Mousetrap.trigger(key);
    };

    it('should not track metrics if keydownTime is not set', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      createComponent();

      await nextTick();
      window.dispatchEvent(new Event('blur'));

      expect(trackEventSpy).not.toHaveBeenCalled();
    });

    it('should track metrics if delta is between 0 and 1000ms', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      createComponent();

      // delta 500 ms
      await simulateKeydown('mod+f', 1000);
      mockGetTime.mockReturnValue(1500);

      window.dispatchEvent(new Event('blur'));

      expect(trackEventSpy).toHaveBeenCalledWith('i_code_review_user_searches_diff', {}, undefined);
    });

    it('should not track metrics if delta is greater than or equal to 1000ms', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      createComponent();

      // delta 1050 ms
      await simulateKeydown('mod+f', 1000);
      mockGetTime.mockReturnValue(2050);

      window.dispatchEvent(new Event('blur'));

      expect(trackEventSpy).not.toHaveBeenCalled();
    });

    it('should not track metrics if delta is negative', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      createComponent();

      // delta -500 ms
      await simulateKeydown('mod+f', 1500);
      mockGetTime.mockReturnValue(1000);

      window.dispatchEvent(new Event('blur'));

      expect(trackEventSpy).not.toHaveBeenCalled();
    });
  });
});
