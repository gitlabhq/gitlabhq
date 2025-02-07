import { GlLoadingIcon, GlPagination } from '@gitlab/ui';
import { createWrapper, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import api from '~/api';
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
import { EVT_DISCUSSIONS_ASSIGNED } from '~/diffs/constants';

import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { Mousetrap } from '~/lib/mousetrap';
import * as urlUtils from '~/lib/utils/url_utility';
import * as commonUtils from '~/lib/utils/common_utils';
import { BV_HIDE_TOOLTIP, DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { stubPerformanceWebAPI } from 'helpers/performance';
import { getDiffFileMock } from 'jest/diffs/mock_data/diff_file';
import waitForPromises from 'helpers/wait_for_promises';
import { diffMetadata } from 'jest/diffs/mock_data/diff_metadata';
import { pinia } from '~/pinia/instance';
import createDiffsStore from '../create_diffs_store';
import diffsMockData from '../mock_data/merge_request_diffs';

const TEST_ENDPOINT = `${TEST_HOST}/diff/endpoint`;
const COMMIT_URL = `${TEST_HOST}/COMMIT/OLD`;
const UPDATED_COMMIT_URL = `${TEST_HOST}/COMMIT/NEW`;
const ENDPOINT_BATCH_URL = `${TEST_HOST}/diff/endpointBatch`;
const ENDPOINT_METADATA_URL = `${TEST_HOST}/diff/endpointMetadata`;

jest.mock('~/api.js');

Vue.use(Vuex);
Vue.use(VueApollo);

function getCollapsedFilesWarning(wrapper) {
  return wrapper.findComponent(CollapsedFilesWarning);
}

describe('diffs/components/app', () => {
  const oldMrTabs = window.mrTabs;
  let store;
  let wrapper;
  let mock;
  let fakeApollo;

  const codeQualityAndSastQueryHandlerSuccess = jest.fn().mockResolvedValue({});

  const createComponent = ({
    props = {},
    extendStore = () => {},
    provisions = {},
    baseConfig = {},
    actions = {},
  } = {}) => {
    fakeApollo = createMockApollo([
      [getMRCodequalityAndSecurityReports, codeQualityAndSastQueryHandlerSuccess],
    ]);

    const provide = {
      ...provisions,
      glFeatures: {
        ...provisions.glFeatures,
      },
    };

    store = createDiffsStore({ actions });
    store.state.diffs.isLoading = false;
    store.state.diffs.isTreeLoaded = true;

    extendStore(store);

    store.dispatch('diffs/setBaseConfig', {
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
      ...baseConfig,
    });

    wrapper = shallowMount(App, {
      apolloProvider: fakeApollo,
      propsData: {
        endpointCoverage: `${TEST_HOST}/diff/endpointCoverage`,
        endpointCodequality: '',
        sastReportAvailable: false,
        projectPath: 'namespace/project',
        currentUser: {},
        changesEmptyStateIllustration: '',
        ...props,
      },
      provide,
      store,
      pinia,
    });
  };

  beforeEach(() => {
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
    it('calls batch methods if diffsBatchLoad is enabled', async () => {
      jest.spyOn(window, 'requestIdleCallback').mockImplementation((fn) => fn());
      createComponent({});
      jest.spyOn(store, 'dispatch');
      await wrapper.vm.fetchData(false);

      expect(store.dispatch.mock.calls).toEqual([
        ['diffs/fetchDiffFilesMeta', undefined],
        ['diffs/fetchDiffFilesBatch', false],
        ['diffs/fetchCoverageFiles', undefined],
      ]);
    });

    it('diff counter to update after fetch with changes', async () => {
      createComponent({
        actions: {
          diffs: {
            fetchDiffFilesMeta: jest.fn().mockResolvedValue({ real_size: 100 }),
          },
        },
      });
      expect(wrapper.vm.diffFilesLength).toEqual(0);
      await wrapper.vm.fetchData(false);
      await waitForPromises();
      expect(wrapper.vm.diffFilesLength).toEqual(100);
    });

    it('diff counter to update after fetch with no changes', async () => {
      createComponent({
        actions: {
          diffs: {
            fetchDiffFilesMeta: jest.fn().mockResolvedValue({ real_size: null }),
          },
        },
      });
      expect(wrapper.vm.diffFilesLength).toEqual(0);
      await wrapper.vm.fetchData(false);
      await waitForPromises();
      expect(wrapper.vm.diffFilesLength).toEqual(0);
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

  it('displays loading icon on loading', () => {
    createComponent({
      extendStore: ({ state }) => {
        state.diffs.isLoading = true;
      },
    });

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('displays loading icon on batch loading', () => {
    createComponent({
      extendStore: ({ state }) => {
        state.diffs.batchLoadingState = 'loading';
      },
    });

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  it('displays diffs container when not loading', () => {
    createComponent({});

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
    expect(wrapper.find('#diffs').exists()).toBe(true);
  });

  it('does not show commit info', () => {
    createComponent({});

    expect(wrapper.find('.blob-commit-info').exists()).toBe(false);
  });

  describe('row highlighting', () => {
    beforeEach(() => {
      window.location.hash = 'ABC_123';
    });

    it('sets highlighted row if hash exists in location object', async () => {
      createComponent({ props: { shouldShow: true } });

      // Component uses $nextTick so we wait until that has finished
      await nextTick();

      expect(store.state.diffs.highlightedRow).toBe('ABC_123');
    });

    it('marks current diff file based on currently highlighted row', async () => {
      createComponent({ props: { shouldShow: true } });

      // Component uses $nextTick so we wait until that has finished
      await nextTick();
      expect(store.state.diffs.currentDiffFileId).toBe('ABC');
    });

    it('renders findings-drawer', () => {
      createComponent({});
      expect(wrapper.findComponent(FindingsDrawer).exists()).toBe(true);
    });
  });

  it('marks current diff file based on currently highlighted row', async () => {
    window.location.hash = 'ABC_123';

    createComponent({ props: { shouldShow: true } });

    // Component uses nextTick so we wait until that has finished
    await nextTick();

    expect(store.state.diffs.currentDiffFileId).toBe('ABC');
  });

  describe('empty state', () => {
    it('renders empty state when no diff files exist', () => {
      createComponent({});

      expect(wrapper.findComponent(NoChanges).exists()).toBe(true);
    });

    it('does not render empty state when diff files exist', () => {
      createComponent({
        extendStore: ({ state }) => {
          state.diffs.diffFiles = ['anything'];
          state.diffs.treeEntries['1'] = { type: 'blob', id: 1 };
        },
      });

      expect(wrapper.findComponent(NoChanges).exists()).toBe(false);
      expect(wrapper.findComponent({ name: 'DynamicScroller' }).props('items')).toStrictEqual(
        store.state.diffs.diffFiles,
      );
    });
  });

  describe('keyboard shortcut navigation', () => {
    let spies = [];
    let moveSpy;
    let jumpSpy;

    function setup(componentProps) {
      createComponent({
        props: componentProps,
        extendStore: ({ state }) => {
          state.diffs.commit = { id: 'SHA123' };
        },
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
      createComponent({
        extendStore: () => {
          store.state.diffs.treeEntries = [
            { type: 'blob', fileHash: '111', path: '111.js' },
            { type: 'blob', fileHash: '222', path: '222.js' },
            { type: 'blob', fileHash: '333', path: '333.js' },
          ];
        },
      });
      spy = jest.spyOn(store, 'dispatch');
    });

    it('jumps to next and previous files in the list', async () => {
      await nextTick();

      wrapper.vm.jumpToFile(+1);

      expect(spy.mock.calls[spy.mock.calls.length - 1]).toEqual([
        'diffs/scrollToFile',
        { path: '222.js' },
      ]);
      store.state.diffs.currentDiffFileId = '222';
      wrapper.vm.jumpToFile(+1);

      expect(spy.mock.calls[spy.mock.calls.length - 1]).toEqual([
        'diffs/scrollToFile',
        { path: '333.js' },
      ]);
      store.state.diffs.currentDiffFileId = '333';
      wrapper.vm.jumpToFile(-1);

      expect(spy.mock.calls[spy.mock.calls.length - 1]).toEqual([
        'diffs/scrollToFile',
        { path: '222.js' },
      ]);
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
    beforeEach(() => {
      setWindowLocation(COMMIT_URL);
      document.title = 'My Title';
    });

    beforeEach(() => {
      jest.spyOn(urlUtils, 'updateHistory');
    });

    it('when the commit changes and the app is not loading it should update the history, refetch the diff data, and update the view', async () => {
      const fetchDiffFilesMetaSpy = jest.fn();
      createComponent({
        extendStore: ({ state }) => {
          state.diffs.commit = { ...state.diffs.commit, id: 'OLD' };
        },
        actions: { diffs: { fetchDiffFilesMeta: fetchDiffFilesMetaSpy } },
      });
      jest.spyOn(wrapper.vm, 'adjustView').mockImplementation(() => {});

      expect(fetchDiffFilesMetaSpy).not.toHaveBeenCalled();
      store.state.diffs.commit = { id: 'NEW' };
      await nextTick();
      expect(urlUtils.updateHistory).toHaveBeenCalledWith({
        title: document.title,
        url: UPDATED_COMMIT_URL,
      });
      expect(fetchDiffFilesMetaSpy).toHaveBeenCalled();
      expect(wrapper.vm.adjustView).toHaveBeenCalled();
    });

    it.each`
      isLoading | oldSha   | newSha
      ${true}   | ${'OLD'} | ${'NEW'}
      ${false}  | ${'NEW'} | ${'NEW'}
    `(
      'given `{ "isLoading": $isLoading, "oldSha": "$oldSha", "newSha": "$newSha" }`, nothing should happen',
      async ({ isLoading, oldSha, newSha }) => {
        const fetchDiffFilesMetaSpy = jest.fn();
        createComponent({
          extendStore: ({ state }) => {
            state.diffs.isLoading = isLoading;
            state.diffs.commit = { ...state.diffs.commit, id: oldSha };
          },

          actions: { diffs: { fetchDiffFilesMeta: fetchDiffFilesMetaSpy } },
        });
        jest.spyOn(wrapper.vm, 'adjustView').mockImplementation(() => {});

        expect(fetchDiffFilesMetaSpy).not.toHaveBeenCalled();
        store.state.diffs.commit = { id: newSha };
        await nextTick();
        expect(urlUtils.updateHistory).not.toHaveBeenCalled();
        expect(fetchDiffFilesMetaSpy).not.toHaveBeenCalled();
        expect(wrapper.vm.adjustView).not.toHaveBeenCalled();
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
      createComponent({
        extendStore: ({ state }) => {
          state.diffs.diffFiles = [getDiffFileMock()];
        },
      });

      expect(wrapper.findComponent(CompareVersions).props()).toMatchObject({
        toggleFileTreeVisible: true,
      });
    });

    it('should render app controls component', () => {
      createComponent({
        extendStore: ({ state }) => {
          state.diffs.diffFiles = diffsMockData;
          state.diffs.realSize = '10';
          state.diffs.addedLines = 15;
          state.diffs.removedLines = 20;
        },
      });

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
      const spy = jest.spyOn(store, 'dispatch');
      await wrapper.findComponent(DiffAppControls).vm.$emit('collapseAllFiles');
      expect(spy).toHaveBeenCalledWith('diffs/collapseAllFiles', undefined);
    });

    it('expands all files', async () => {
      createComponent();
      jest.spyOn(store, 'dispatch');
      await wrapper.findComponent(DiffAppControls).vm.$emit('expandAllFiles');
      expect(store.dispatch).toHaveBeenCalledWith('diffs/expandAllFiles', undefined);
    });

    it('switches whitespace mode', async () => {
      createComponent();
      const spy = jest.spyOn(store, 'dispatch');
      await wrapper.findComponent(DiffAppControls).vm.$emit('toggleWhitespace', false);
      expect(spy).toHaveBeenCalledWith('diffs/setShowWhitespace', { showWhitespace: false });
    });

    it('switches view mode', async () => {
      createComponent();
      const spy = jest.spyOn(store, 'dispatch');
      await wrapper.findComponent(DiffAppControls).vm.$emit('updateDiffViewType', 'parallel');
      expect(spy).toHaveBeenCalledWith('diffs/setDiffViewType', 'parallel');
    });

    it('enables file by file mode', async () => {
      createComponent();
      const spy = jest.spyOn(store, 'dispatch').mockImplementation(() => {});
      await wrapper.findComponent(DiffAppControls).vm.$emit('toggleFileByFile');
      expect(spy).toHaveBeenCalledWith('diffs/setFileByFile', { fileByFile: true });
    });

    describe('warnings', () => {
      describe('hidden files', () => {
        it('should render hidden files warning if render overflow warning is present', () => {
          createComponent({
            extendStore: ({ state }) => {
              state.diffs.renderOverflowWarning = true;
              state.diffs.realSize = '5';
              state.diffs.plainDiffPath = 'plain diff path';
              state.diffs.emailPatchPath = 'email patch path';
              state.diffs.size = 1;
              state.diffs.treeEntries = {
                111: { type: 'blob', fileHash: '111', path: '111.js' },
              };
            },
          });

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
          createComponent({
            extendStore: ({ state }) => {
              state.diffs.diffFiles = [{ viewer: { automaticallyCollapsed: true } }];
            },
          });

          expect(getCollapsedFilesWarning(wrapper).exists()).toBe(true);
        });

        it('should not render the collapsed files warning if there are no automatically collapsed files', () => {
          createComponent({
            extendStore: ({ state }) => {
              state.diffs.diffFiles = [
                { viewer: { automaticallyCollapsed: false, manuallyCollapsed: true } },
                { viewer: { automaticallyCollapsed: false, manuallyCollapsed: false } },
              ];
            },
          });

          expect(getCollapsedFilesWarning(wrapper).exists()).toBe(false);
        });
      });
    });

    it('should display commit widget if store has a commit', () => {
      createComponent({
        extendStore: () => {
          store.state.diffs.commit = { author: 'John Doe' };
        },
      });

      expect(wrapper.findComponent(CommitWidget).exists()).toBe(true);
    });

    it('should display diff file if there are diff files', () => {
      createComponent({
        extendStore: ({ state }) => {
          state.diffs.diffFiles = [{ file_hash: '111', file_path: '111.js' }];
          state.diffs.treeEntries = {
            111: { type: 'blob', fileHash: '111', path: '111.js' },
            123: { type: 'blob', fileHash: '123', path: '123.js' },
            312: { type: 'blob', fileHash: '312', path: '312.js' },
          };
        },
      });

      expect(wrapper.findComponent({ name: 'DynamicScroller' }).exists()).toBe(true);
      expect(wrapper.findComponent({ name: 'DynamicScroller' }).props('items')).toStrictEqual(
        store.state.diffs.diffFiles,
      );
    });

    describe('File browser', () => {
      it('should always render diffs file tree', () => {
        createComponent({});
        expect(wrapper.findComponent(DiffsFileTree).exists()).toBe(true);
      });

      it('should pass visible to file tree as true when files are present', () => {
        createComponent({
          extendStore: ({ state }) => {
            state.diffs.treeEntries = { 111: { type: 'blob', fileHash: '111', path: '111.js' } };
          },
        });
        expect(wrapper.findComponent(DiffsFileTree).props('visible')).toBe(true);
      });

      it('should pass visible to file tree as false without files', () => {
        createComponent({});
        expect(wrapper.findComponent(DiffsFileTree).props('visible')).toBe(false);
      });

      it('should hide file tree when toggled', async () => {
        createComponent({
          extendStore: ({ state }) => {
            state.diffs.treeEntries = { 111: { type: 'blob', fileHash: '111', path: '111.js' } };
          },
        });
        wrapper.findComponent(DiffsFileTree).vm.$emit('toggled');
        await nextTick();
        expect(wrapper.findComponent(DiffsFileTree).props('visible')).toBe(false);
      });

      it('should show file tree when toggled', async () => {
        createComponent({
          extendStore: ({ state }) => {
            state.diffs.treeEntries = { 111: { type: 'blob', fileHash: '111', path: '111.js' } };
          },
        });
        wrapper.findComponent(DiffsFileTree).vm.$emit('toggled');
        await nextTick();
        wrapper.findComponent(DiffsFileTree).vm.$emit('toggled');
        await nextTick();
        expect(wrapper.findComponent(DiffsFileTree).props('visible')).toBe(true);
      });

      it('should handle clickFile events', () => {
        const file = { path: '111.js' };
        createComponent({
          extendStore: ({ state }) => {
            state.diffs.treeEntries = { 111: { type: 'blob', fileHash: '111', path: '111.js' } };
          },
        });
        jest.spyOn(store, 'dispatch');
        wrapper.findComponent(DiffsFileTree).vm.$emit('clickFile', file);
        expect(store.dispatch).toHaveBeenCalledWith('diffs/goToFile', { path: file.path });
      });
    });
  });

  describe('setTreeDisplay', () => {
    afterEach(() => {
      localStorage.removeItem('mr_tree_show');
    });

    it('calls setShowTreeList when only 1 file', () => {
      createComponent({
        extendStore: ({ state }) => {
          state.diffs.treeEntries = { 123: { type: 'blob', fileHash: '123' } };
        },
      });
      jest.spyOn(store, 'dispatch');
      wrapper.vm.setTreeDisplay();

      expect(store.dispatch).toHaveBeenCalledWith('diffs/setShowTreeList', {
        showTreeList: false,
        saving: false,
      });
    });

    it('calls setShowTreeList with true when more than 1 file is in tree entries map', () => {
      createComponent({
        extendStore: ({ state }) => {
          state.diffs.treeEntries = {
            111: { type: 'blob', fileHash: '111', path: '111.js' },
            123: { type: 'blob', fileHash: '123', path: '123.js' },
          };
        },
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

      createComponent({
        extendStore: ({ state }) => {
          state.diffs.treeEntries['123'] = { sha: '123' };
        },
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
    let hashSpy;

    beforeEach(() => {
      hashSpy = jest.spyOn(commonUtils, 'handleLocationHash');
    });

    it('renders a single diff', async () => {
      createComponent({
        extendStore: ({ state }) => {
          state.diffs.treeEntries = {
            123: { type: 'blob', fileHash: '123' },
            312: { type: 'blob', fileHash: '312' },
          };
          state.diffs.diffFiles.push({ file_hash: '312' });
        },
        baseConfig: { viewDiffsFileByFile: true },
      });

      await nextTick();

      expect(wrapper.findAllComponents(DiffFile).length).toBe(1);
    });

    describe('rechecking the url hash for scrolling', () => {
      const advanceAndCheckCalls = (count = 0) => {
        jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
        expect(hashSpy).toHaveBeenCalledTimes(count);
      };

      it('re-checks one time after the file finishes loading', () => {
        createComponent({
          extendStore: ({ state }) => {
            state.diffs.diffFiles = [{ isLoadingFullFile: true }];
          },
          baseConfig: { viewDiffsFileByFile: true },
        });

        // The hash check is not called if the file is still marked as loading
        expect(hashSpy).toHaveBeenCalledTimes(0);
        eventHub.$emit(EVT_DISCUSSIONS_ASSIGNED);
        advanceAndCheckCalls();
        eventHub.$emit(EVT_DISCUSSIONS_ASSIGNED);
        advanceAndCheckCalls();
        // Once the file has finished loading, it calls through to check the hash
        store.state.diffs.diffFiles[0].isLoadingFullFile = false;
        eventHub.$emit(EVT_DISCUSSIONS_ASSIGNED);
        advanceAndCheckCalls(1);
        // No further scrolls happen after one hash check / scroll
        eventHub.$emit(EVT_DISCUSSIONS_ASSIGNED);
        advanceAndCheckCalls(1);
        eventHub.$emit(EVT_DISCUSSIONS_ASSIGNED);
        advanceAndCheckCalls(1);
      });

      it('does not re-check when not in single-file mode', () => {
        createComponent({});

        eventHub.$emit(EVT_DISCUSSIONS_ASSIGNED);

        expect(hashSpy).not.toHaveBeenCalled();
      });
    });

    describe('pagination', () => {
      const fileByFileNav = () => wrapper.find('[data-testid="file-by-file-navigation"]');
      const paginator = () => fileByFileNav().findComponent(GlPagination);

      it('sets previous button as disabled', async () => {
        createComponent({
          extendStore: ({ state }) => {
            state.diffs.treeEntries = {
              123: { type: 'blob', fileHash: '123' },
              312: { type: 'blob', fileHash: '312' },
            };
          },
          baseConfig: { viewDiffsFileByFile: true },
        });

        await nextTick();

        expect(paginator().attributes('prevpage')).toBe(undefined);
        expect(paginator().attributes('nextpage')).toBe('2');
      });

      it('sets next button as disabled', async () => {
        createComponent({
          extendStore: ({ state }) => {
            state.diffs.treeEntries = {
              123: { type: 'blob', fileHash: '123' },
              312: { type: 'blob', fileHash: '312' },
            };
            state.diffs.currentDiffFileId = '312';
          },
          baseConfig: { viewDiffsFileByFile: true },
        });

        await nextTick();

        expect(paginator().attributes('prevpage')).toBe('1');
        expect(paginator().attributes('nextpage')).toBe(undefined);
      });

      it("doesn't display when there's fewer than 2 files", async () => {
        createComponent({
          extendStore: ({ state }) => {
            state.diffs.treeEntries = { 123: { type: 'blob', fileHash: '123' } };
            state.diffs.currentDiffFileId = '123';
          },
          baseConfig: { viewDiffsFileByFile: true },
        });

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
          const navigateToDiffFileIndexSpy = jest.fn();
          createComponent({
            extendStore: ({ state }) => {
              state.diffs.treeEntries = {
                123: { type: 'blob', fileHash: '123', filePaths: { old: '1234', new: '123' } },
                312: { type: 'blob', fileHash: '312', filePaths: { old: '3124', new: '312' } },
              };
              state.diffs.currentDiffFileId = currentDiffFileId;
            },
            baseConfig: { viewDiffsFileByFile: true },
            actions: { diffs: { navigateToDiffFileIndex: navigateToDiffFileIndexSpy } },
          });

          await nextTick();
          paginator().vm.$emit('input', targetFile);
          await nextTick();
          expect(navigateToDiffFileIndexSpy).toHaveBeenLastCalledWith(
            expect.anything(),
            targetFile - 1,
          );
        },
      );
    });

    describe('non-UI navigation', () => {
      describe('in single-file review mode', () => {
        let currentHash;
        let fetchFbf;

        beforeEach(() => {
          currentHash = jest.fn();
          fetchFbf = jest.fn();
          window.location.hash = '123';

          createComponent({
            actions: {
              diffs: {
                setCurrentFileHash: currentHash,
                fetchFileByFile: fetchFbf,
              },
            },
            extendStore: ({ state }) => {
              state.diffs.treeEntries = {
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
              state.diffs.diffFiles = [{ file_hash: '123' }, { file_hash: '312' }];
            },
            baseConfig: { viewDiffsFileByFile: true },
          });
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

            expect(currentHash).toHaveBeenCalledWith(expect.anything(), updated);
            expect(fetchFbf).toHaveBeenCalled();
          },
        );
      });

      describe('in "normal" (multi-file) mode', () => {
        let currentHash;
        let fetchFbf;

        beforeEach(() => {
          currentHash = jest.fn();
          fetchFbf = jest.fn();
          window.location.hash = '123';

          createComponent({
            actions: {
              diffs: {
                setCurrentFileHash: currentHash,
                fetchFileByFile: fetchFbf,
              },
            },
            extendStore: ({ state }) => {
              state.diffs.treeEntries = {
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
              state.diffs.diffFiles = [{ file_hash: '123' }, { file_hash: '312' }];
            },
          });
        });

        it('does not react to the hash changing when in regular (multi-file) mode', async () => {
          window.location.hash = '312';
          window.dispatchEvent(new Event('hashchange'));

          await nextTick();

          expect(currentHash).not.toHaveBeenCalled();
          expect(fetchFbf).not.toHaveBeenCalled();
        });
      });
    });
  });

  describe('autoscroll', () => {
    let loadCollapsedDiffSpy;

    beforeEach(() => {
      loadCollapsedDiffSpy = jest.fn().mockResolvedValue();
      createComponent({
        extendStore: () => {},
        actions: { diffs: { loadCollapsedDiff: loadCollapsedDiffSpy } },
      });

      store.state.diffs.diffFiles = [
        {
          file_hash: '1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a',
          highlighted_diff_lines: [],
          viewer: { manuallyCollapsed: true },
        },
      ];
    });

    it('does nothing if the location hash does not include a file hash', () => {
      window.location.hash = 'not_a_file_hash';
      eventHub.$emit('doneLoadingBatches');
      expect(loadCollapsedDiffSpy).not.toHaveBeenCalled();
    });

    it('requests that the correct file be loaded', () => {
      store.state.diffs.mergeRequestDiff = {};
      window.location.hash = '1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_0_1';
      expect(loadCollapsedDiffSpy).toHaveBeenCalledTimes(0);
      eventHub.$emit('doneLoadingBatches');
      expect(loadCollapsedDiffSpy).toHaveBeenCalledTimes(1);
      expect(loadCollapsedDiffSpy).toHaveBeenLastCalledWith(expect.anything(), {
        file: store.state.diffs.diffFiles[0],
      });
    });

    it('does nothing when file is not collapsed', () => {
      store.state.diffs.diffFiles[0].viewer.manuallyCollapsed = false;
      window.location.hash = '1c497fbb3a46b78edf04cc2a2fa33f67e3ffbe2a_0_1';
      eventHub.$emit('doneLoadingBatches');
      expect(loadCollapsedDiffSpy).not.toHaveBeenCalled();
    });
  });

  describe('linked file', () => {
    const linkedFileUrl = 'http://localhost.test/linked-file';
    let linkedFile;

    beforeEach(() => {
      linkedFile = getDiffFileMock();
      mock.onGet(linkedFileUrl).reply(HTTP_STATUS_OK, { diff_files: [linkedFile] });
      mock
        .onGet(new RegExp(ENDPOINT_BATCH_URL))
        .reply(HTTP_STATUS_OK, { diff_files: [], pagination: {} });
      mock.onGet(new RegExp(ENDPOINT_METADATA_URL)).reply(HTTP_STATUS_OK, diffMetadata);

      createComponent({ props: { shouldShow: true, linkedFileUrl } });
    });

    it('fetches and displays the file', async () => {
      await waitForPromises();

      expect(wrapper.findComponent({ name: 'DynamicScroller' }).props('items')[0].file_hash).toBe(
        linkedFile.file_hash,
      );
    });

    it('shows a spinner during loading', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('draft comments', () => {
    let trackingSpy;

    beforeEach(() => {
      trackingSpy = mockTracking(undefined, window.document, jest.spyOn);
    });

    describe('when adding a new comment to an existing review', () => {
      it('sends the correct tracking event', () => {
        createComponent({ props: { shouldShow: true } });
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
        createComponent({ props: { shouldShow: true } });
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
      createComponent({ props: { shouldShow: true } });
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

  describe('track "trackRedisHllUserEvent" and "trackRedisCounterEvent" metrics', () => {
    let mockGetTime;

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
      createComponent({ props: { shouldShow: true } });

      await nextTick();
      window.dispatchEvent(new Event('blur'));

      expect(api.trackRedisHllUserEvent).not.toHaveBeenCalled();
      expect(api.trackRedisCounterEvent).not.toHaveBeenCalled();
    });

    it('should track metrics if delta is between 0 and 1000ms', async () => {
      createComponent({ props: { shouldShow: true } });

      // delta 500 ms
      await simulateKeydown('mod+f', 1000);
      mockGetTime.mockReturnValue(1500);

      window.dispatchEvent(new Event('blur'));

      expect(api.trackRedisHllUserEvent).toHaveBeenCalledWith('i_code_review_user_searches_diff');
      expect(api.trackRedisCounterEvent).toHaveBeenCalledWith('diff_searches');
    });

    it('should not track metrics if delta is greater than or equal to 1000ms', async () => {
      createComponent({ props: { shouldShow: true } });

      // delta 1050 ms
      await simulateKeydown('mod+f', 1000);
      mockGetTime.mockReturnValue(2050);

      window.dispatchEvent(new Event('blur'));

      expect(api.trackRedisHllUserEvent).not.toHaveBeenCalled();
      expect(api.trackRedisCounterEvent).not.toHaveBeenCalled();
    });

    it('should not track metrics if delta is negative', async () => {
      createComponent({ props: { shouldShow: true } });

      // delta -500 ms
      await simulateKeydown('mod+f', 1500);
      mockGetTime.mockReturnValue(1000);

      window.dispatchEvent(new Event('blur'));

      expect(api.trackRedisHllUserEvent).not.toHaveBeenCalled();
      expect(api.trackRedisCounterEvent).not.toHaveBeenCalled();
    });
  });
});
