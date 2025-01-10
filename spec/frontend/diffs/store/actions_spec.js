import MockAdapter from 'axios-mock-adapter';
import api from '~/api';
import Cookies from '~/lib/utils/cookies';
import waitForPromises from 'helpers/wait_for_promises';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';
import { getDiffFileMock } from 'jest/diffs/mock_data/diff_file';
import {
  DIFF_VIEW_COOKIE_NAME,
  INLINE_DIFF_VIEW_TYPE,
  PARALLEL_DIFF_VIEW_TYPE,
  EVT_MR_PREPARED,
} from '~/diffs/constants';
import {
  BUILDING_YOUR_MR,
  SOMETHING_WENT_WRONG,
  ENCODED_FILE_PATHS_TITLE,
  ENCODED_FILE_PATHS_MESSAGE,
} from '~/diffs/i18n';
import * as diffActions from '~/diffs/store/actions';
import * as types from '~/diffs/store/mutation_types';
import * as utils from '~/diffs/store/utils';
import * as treeWorkerUtils from '~/diffs/utils/tree_worker_utils';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import * as commonUtils from '~/lib/utils/common_utils';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import eventHub from '~/notes/event_hub';
import diffsEventHub from '~/diffs/event_hub';
import { handleLocationHash, historyPushState, scrollToElement } from '~/lib/utils/common_utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { diffMetadata } from '../mock_data/diff_metadata';

jest.mock('~/alert');

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal');
confirmAction.mockResolvedValueOnce(false);

const endpointDiffForPath = '/diffs/set/endpoint/path';

describe('DiffsStoreActions', () => {
  let mock;

  useLocalStorageSpy();

  const originalMethods = {
    requestAnimationFrame: global.requestAnimationFrame,
    requestIdleCallback: global.requestIdleCallback,
  };

  beforeEach(() => {
    jest.spyOn(window.history, 'pushState');
    jest.spyOn(commonUtils, 'historyPushState');
    jest.spyOn(commonUtils, 'handleLocationHash').mockImplementation(() => null);
    jest.spyOn(commonUtils, 'scrollToElement').mockImplementation(() => null);
    jest.spyOn(utils, 'convertExpandLines').mockImplementation(() => null);
    jest.spyOn(utils, 'idleCallback').mockImplementation(() => null);
    ['requestAnimationFrame', 'requestIdleCallback'].forEach((method) => {
      global[method] = (cb) => {
        cb({ timeRemaining: () => 10 });
      };
    });
  });

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    ['requestAnimationFrame', 'requestIdleCallback'].forEach((method) => {
      global[method] = originalMethods[method];
    });
    createAlert.mockClear();
    mock.restore();
  });

  describe('setBaseConfig', () => {
    it('should set given endpoint and project path', () => {
      const endpoint = '/diffs/set/endpoint';
      const endpointMetadata = '/diffs/set/endpoint/metadata';
      const endpointBatch = '/diffs/set/endpoint/batch';
      const endpointCoverage = '/diffs/set/coverage_reports';
      const projectPath = '/root/project';
      const dismissEndpoint = '/-/user_callouts';
      const showSuggestPopover = false;
      const mrReviews = {
        a: ['z', 'hash:a'],
        b: ['y', 'hash:a'],
      };
      const diffViewType = 'inline';

      return testAction(
        diffActions.setBaseConfig,
        {
          endpoint,
          endpointBatch,
          endpointDiffForPath,
          endpointMetadata,
          endpointCoverage,
          projectPath,
          dismissEndpoint,
          showSuggestPopover,
          mrReviews,
          diffViewType,
        },
        {
          endpoint: '',
          endpointBatch: '',
          endpointDiffForPath: '',
          endpointMetadata: '',
          endpointCoverage: '',
          projectPath: '',
          dismissEndpoint: '',
          showSuggestPopover: true,
        },
        [
          {
            type: types.SET_BASE_CONFIG,
            payload: {
              endpoint,
              endpointMetadata,
              endpointBatch,
              endpointDiffForPath,
              endpointCoverage,
              projectPath,
              dismissEndpoint,
              showSuggestPopover,
              mrReviews,
              diffViewType,
            },
          },
          {
            type: types.SET_DIFF_FILE_VIEWED,
            payload: { id: 'z', seen: true },
          },
          {
            type: types.SET_DIFF_FILE_VIEWED,
            payload: { id: 'a', seen: true },
          },
          {
            type: types.SET_DIFF_FILE_VIEWED,
            payload: { id: 'y', seen: true },
          },
        ],
        [],
      );
    });
  });

  describe('prefetchSingleFile', () => {
    beforeEach(() => {
      window.location.hash = 'e334a2a10f036c00151a04cea7938a5d4213a818';
    });

    it('should do nothing if the tree entry is already loading', () => {
      return testAction(diffActions.prefetchSingleFile, { diffLoading: true }, {}, [], []);
    });

    it('should do nothing if the tree entry has already been marked as loaded', () => {
      return testAction(
        diffActions.prefetchSingleFile,
        { diffLoaded: true },
        {
          flatBlobsList: [
            { fileHash: 'e334a2a10f036c00151a04cea7938a5d4213a818', diffLoaded: true },
          ],
        },
        [],
        [],
      );
    });

    describe('when a tree entry exists for the file, but it has not been marked as loaded', () => {
      let state;
      let getters;
      let commit;
      let hubSpy;
      const defaultParams = {
        old_path: 'old/123',
        new_path: 'new/123',
        w: '1',
        view: 'inline',
        diff_head: true,
      };
      const diffForPath = mergeUrlParams(defaultParams, endpointDiffForPath);
      const treeEntry = {
        fileHash: 'e334a2a10f036c00151a04cea7938a5d4213a818',
        filePaths: { old: 'old/123', new: 'new/123' },
      };
      const fileResult = {
        diff_files: [{ file_hash: 'e334a2a10f036c00151a04cea7938a5d4213a818' }],
      };

      beforeEach(() => {
        commit = jest.fn();
        state = {
          endpointDiffForPath,
          diffFiles: [],
        };
        getters = {
          flatBlobsList: [treeEntry],
          getDiffFileByHash(hash) {
            return state.diffFiles?.find((entry) => entry.file_hash === hash);
          },
        };
        hubSpy = jest.spyOn(diffsEventHub, '$emit');
      });

      it('does nothing if the file already exists in the loaded diff files', () => {
        state.diffFiles = fileResult.diff_files;

        return testAction(diffActions.prefetchSingleFile, treeEntry, getters, [], []);
      });

      it('does some standard work every time', async () => {
        mock.onGet(diffForPath).reply(HTTP_STATUS_OK, fileResult);

        await diffActions.prefetchSingleFile({ state, getters, commit }, treeEntry);

        expect(commit).toHaveBeenCalledWith(types.TREE_ENTRY_DIFF_LOADING, {
          path: treeEntry.filePaths.new,
        });

        // wait for the mocked network request to return
        await waitForPromises();

        expect(commit).toHaveBeenCalledWith(types.SET_DIFF_DATA_BATCH, fileResult);

        expect(hubSpy).toHaveBeenCalledWith('diffFilesModified');
      });

      it('should fetch data without commit ID', async () => {
        getters.commitId = null;
        mock.onGet(diffForPath).reply(HTTP_STATUS_OK, fileResult);

        await diffActions.prefetchSingleFile({ state, getters, commit }, treeEntry);

        // wait for the mocked network request to return and start processing the .then
        await waitForPromises();

        // This tests that commit_id is NOT added, if there isn't one in the store
        expect(mock.history.get[0].url).toEqual(diffForPath);
      });

      it('should fetch data with commit ID', async () => {
        const finalPath = mergeUrlParams(
          { ...defaultParams, commit_id: '123' },
          endpointDiffForPath,
        );

        getters.commitId = '123';
        mock.onGet(finalPath).reply(HTTP_STATUS_OK, fileResult);

        await diffActions.prefetchSingleFile({ state, getters, commit }, treeEntry);

        // wait for the mocked network request to return and start processing the .then
        await waitForPromises();

        expect(mock.history.get[0].url).toContain(
          'old_path=old%2F123&new_path=new%2F123&w=1&view=inline&commit_id=123',
        );
      });

      describe('version parameters', () => {
        const diffId = '4';
        const startSha = 'abc';
        const pathRoot = 'a/a/-/merge_requests/1';

        it('fetches the data when there is no mergeRequestDiff', async () => {
          diffActions.prefetchSingleFile({ state, getters, commit }, treeEntry);

          // wait for the mocked network request to return and start processing the .then
          await waitForPromises();

          expect(mock.history.get[0].url).toEqual(diffForPath);
        });

        it.each`
          desc                                   | versionPath                                              | start_sha    | diff_id
          ${'no additional version information'} | ${`${pathRoot}?search=terms`}                            | ${undefined} | ${undefined}
          ${'the diff_id'}                       | ${`${pathRoot}?diff_id=${diffId}`}                       | ${undefined} | ${diffId}
          ${'the start_sha'}                     | ${`${pathRoot}?start_sha=${startSha}`}                   | ${startSha}  | ${undefined}
          ${'all available version information'} | ${`${pathRoot}?diff_id=${diffId}&start_sha=${startSha}`} | ${startSha}  | ${diffId}
        `('fetches the data and includes $desc', async ({ versionPath, start_sha, diff_id }) => {
          const finalPath = mergeUrlParams(
            { ...defaultParams, diff_id, start_sha },
            endpointDiffForPath,
          );
          state.mergeRequestDiff = { version_path: versionPath };
          state.endpointBatch = versionPath;
          mock.onGet(finalPath).reply(HTTP_STATUS_OK, fileResult);

          diffActions.prefetchSingleFile({ state, getters, commit }, treeEntry);

          // wait for the mocked network request to return
          await waitForPromises();

          expect(mock.history.get[0].url).toEqual(finalPath);
        });
      });

      describe('when the prefetch fails', () => {
        beforeEach(() => {
          mock.onGet(diffForPath).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        });

        it('should commit a mutation to set the tree entry diff loading to false', async () => {
          diffActions.prefetchSingleFile({ state, getters, commit }, treeEntry);

          // wait for the mocked network request to return
          await waitForPromises();

          expect(commit).toHaveBeenCalledWith(types.TREE_ENTRY_DIFF_LOADING, {
            path: treeEntry.filePaths.new,
            loading: false,
          });
        });
      });
    });
  });

  describe('fetchFileByFile', () => {
    beforeEach(() => {
      window.location.hash = 'e334a2a10f036c00151a04cea7938a5d4213a818';
    });

    it('should do nothing if there is no tree entry for the file ID', () => {
      return testAction(diffActions.fetchFileByFile, {}, { flatBlobsList: [] }, [], []);
    });

    it('should do nothing if the tree entry for the file ID has already been marked as loaded', () => {
      return testAction(
        diffActions.fetchFileByFile,
        {},
        {
          flatBlobsList: [
            { fileHash: 'e334a2a10f036c00151a04cea7938a5d4213a818', diffLoaded: true },
          ],
        },
        [],
        [],
      );
    });

    describe('when a tree entry exists for the file, but it has not been marked as loaded', () => {
      let state;
      let getters;
      let commit;
      let hubSpy;
      const defaultParams = {
        old_path: 'old/123',
        new_path: 'new/123',
        w: '1',
        view: 'inline',
        diff_head: true,
      };
      const diffForPath = mergeUrlParams(defaultParams, endpointDiffForPath);
      const treeEntry = {
        fileHash: 'e334a2a10f036c00151a04cea7938a5d4213a818',
        filePaths: { old: 'old/123', new: 'new/123' },
      };
      const fileResult = {
        diff_files: [{ file_hash: 'e334a2a10f036c00151a04cea7938a5d4213a818' }],
      };

      beforeEach(() => {
        commit = jest.fn();
        state = {
          endpointDiffForPath,
          diffFiles: [],
        };
        getters = {
          flatBlobsList: [treeEntry],
          getDiffFileByHash(hash) {
            return state.diffFiles?.find((entry) => entry.file_hash === hash);
          },
        };
        hubSpy = jest.spyOn(diffsEventHub, '$emit');
      });

      it('does nothing if the file already exists in the loaded diff files', () => {
        state.diffFiles = fileResult.diff_files;

        return testAction(diffActions.fetchFileByFile, state, getters, [], []);
      });

      it('does some standard work every time', async () => {
        mock.onGet(diffForPath).reply(HTTP_STATUS_OK, fileResult);

        await diffActions.fetchFileByFile({ state, getters, commit });

        expect(commit).toHaveBeenCalledWith(types.SET_BATCH_LOADING_STATE, 'loading');
        expect(commit).toHaveBeenCalledWith(types.SET_RETRIEVING_BATCHES, true);

        // wait for the mocked network request to return and start processing the .then
        await waitForPromises();

        expect(commit).toHaveBeenCalledWith(types.SET_DIFF_DATA_BATCH, fileResult);
        expect(commit).toHaveBeenCalledWith(types.SET_BATCH_LOADING_STATE, 'loaded');

        expect(hubSpy).toHaveBeenCalledWith('diffFilesModified');
      });

      it.each`
        urlHash               | diffFiles                | expected
        ${treeEntry.fileHash} | ${[]}                    | ${''}
        ${'abcdef1234567890'} | ${fileResult.diff_files} | ${'e334a2a10f036c00151a04cea7938a5d4213a818'}
      `(
        "sets the current file to the first diff file ('$id') if it's not a note hash and there isn't a current ID set",
        async ({ urlHash, diffFiles, expected }) => {
          window.location.hash = urlHash;
          mock.onGet(diffForPath).reply(HTTP_STATUS_OK, fileResult);
          state.diffFiles = diffFiles;

          await diffActions.fetchFileByFile({ state, getters, commit });

          // wait for the mocked network request to return and start processing the .then
          await waitForPromises();

          expect(commit).toHaveBeenCalledWith(types.SET_CURRENT_DIFF_FILE, expected);
        },
      );

      it('should fetch data without commit ID', async () => {
        getters.commitId = null;
        mock.onGet(diffForPath).reply(HTTP_STATUS_OK, fileResult);

        await diffActions.fetchFileByFile({ state, getters, commit });

        // wait for the mocked network request to return and start processing the .then
        await waitForPromises();

        // This tests that commit_id is NOT added, if there isn't one in the store
        expect(mock.history.get[0].url).toEqual(diffForPath);
      });

      it('should fetch data with commit ID', async () => {
        const finalPath = mergeUrlParams(
          { ...defaultParams, commit_id: '123' },
          endpointDiffForPath,
        );

        getters.commitId = '123';
        mock.onGet(finalPath).reply(HTTP_STATUS_OK, fileResult);

        await diffActions.fetchFileByFile({ state, getters, commit });

        // wait for the mocked network request to return and start processing the .then
        await waitForPromises();

        expect(mock.history.get[0].url).toContain(
          'old_path=old%2F123&new_path=new%2F123&w=1&view=inline&commit_id=123',
        );
      });

      describe('version parameters', () => {
        const diffId = '4';
        const startSha = 'abc';
        const pathRoot = 'a/a/-/merge_requests/1';

        it('fetches the data when there is no mergeRequestDiff', async () => {
          diffActions.fetchFileByFile({ state, getters, commit });

          // wait for the mocked network request to return and start processing the .then
          await waitForPromises();

          expect(mock.history.get[0].url).toEqual(diffForPath);
        });

        it.each`
          desc                                   | versionPath                                              | start_sha    | diff_id
          ${'no additional version information'} | ${`${pathRoot}?search=terms`}                            | ${undefined} | ${undefined}
          ${'the diff_id'}                       | ${`${pathRoot}?diff_id=${diffId}`}                       | ${undefined} | ${diffId}
          ${'the start_sha'}                     | ${`${pathRoot}?start_sha=${startSha}`}                   | ${startSha}  | ${undefined}
          ${'all available version information'} | ${`${pathRoot}?diff_id=${diffId}&start_sha=${startSha}`} | ${startSha}  | ${diffId}
        `('fetches the data and includes $desc', async ({ versionPath, start_sha, diff_id }) => {
          const finalPath = mergeUrlParams(
            { ...defaultParams, diff_id, start_sha },
            endpointDiffForPath,
          );
          state.endpointBatch = versionPath;
          mock.onGet(finalPath).reply(HTTP_STATUS_OK, fileResult);

          diffActions.fetchFileByFile({ state, getters, commit });

          // wait for the mocked network request to return and start processing the .then
          await waitForPromises();

          expect(mock.history.get[0].url).toEqual(finalPath);
        });
      });
    });
  });

  describe('fetchDiffFilesBatch', () => {
    it('should fetch batch diff files', () => {
      const endpointBatch = '/fetch/diffs_batch';
      const res1 = { diff_files: [{ file_hash: 'test' }], pagination: { total_pages: 2 } };
      const res2 = { diff_files: [{ file_hash: 'test2' }], pagination: { total_pages: 2 } };
      mock
        .onGet(
          mergeUrlParams(
            {
              w: '1',
              view: 'inline',
              page: 0,
              per_page: 5,
            },
            endpointBatch,
          ),
        )
        .reply(HTTP_STATUS_OK, res1)
        .onGet(
          mergeUrlParams(
            {
              w: '1',
              view: 'inline',
              page: 5,
              per_page: 7,
            },
            endpointBatch,
          ),
        )
        .reply(HTTP_STATUS_OK, res2);

      return testAction(
        diffActions.fetchDiffFilesBatch,
        undefined,
        { endpointBatch, diffViewType: 'inline', diffFiles: [], perPage: 5 },
        [
          { type: types.SET_BATCH_LOADING_STATE, payload: 'loading' },
          { type: types.SET_RETRIEVING_BATCHES, payload: true },
          { type: types.SET_DIFF_DATA_BATCH, payload: { diff_files: res1.diff_files } },
          { type: types.SET_BATCH_LOADING_STATE, payload: 'loaded' },
          { type: types.SET_CURRENT_DIFF_FILE, payload: 'test' },
          { type: types.SET_DIFF_DATA_BATCH, payload: { diff_files: res2.diff_files } },
          { type: types.SET_BATCH_LOADING_STATE, payload: 'loaded' },
          { type: types.SET_CURRENT_DIFF_FILE, payload: 'test2' },
          { type: types.SET_RETRIEVING_BATCHES, payload: false },
        ],
        [],
      );
    });
  });

  describe('fetchDiffFilesMeta', () => {
    const endpointMetadata = '/fetch/diffs_metadata.json?view=inline&w=0';
    const noFilesData = { ...diffMetadata };

    beforeEach(() => {
      delete noFilesData.diff_files;
    });

    it('should fetch diff meta information', () => {
      mock.onGet(endpointMetadata).reply(HTTP_STATUS_OK, diffMetadata);

      return testAction(
        diffActions.fetchDiffFilesMeta,
        {},
        { endpointMetadata, diffViewType: 'inline', showWhitespace: true },
        [
          { type: types.SET_LOADING, payload: true },
          { type: types.SET_LOADING, payload: false },
          { type: types.SET_MERGE_REQUEST_DIFFS, payload: diffMetadata.merge_request_diffs },
          { type: types.SET_DIFF_METADATA, payload: noFilesData },
          // Workers are synchronous in Jest environment (see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58805)
          {
            type: types.SET_TREE_DATA,
            payload: treeWorkerUtils.generateTreeList(diffMetadata.diff_files),
          },
        ],
        [],
      );
    });

    describe('when diff metadata returns has_encoded_file_paths as true', () => {
      beforeEach(() => {
        mock
          .onGet(endpointMetadata)
          .reply(HTTP_STATUS_OK, { ...diffMetadata, has_encoded_file_paths: true });
      });

      it('should show a non-dismissible alert', async () => {
        await testAction(
          diffActions.fetchDiffFilesMeta,
          {},
          { endpointMetadata, diffViewType: 'inline', showWhitespace: true },
          [
            { type: types.SET_LOADING, payload: true },
            { type: types.SET_LOADING, payload: false },
            { type: types.SET_MERGE_REQUEST_DIFFS, payload: diffMetadata.merge_request_diffs },
            {
              type: types.SET_DIFF_METADATA,
              payload: { ...noFilesData, has_encoded_file_paths: true },
            },
            // Workers are synchronous in Jest environment (see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58805)
            {
              type: types.SET_TREE_DATA,
              payload: treeWorkerUtils.generateTreeList(diffMetadata.diff_files),
            },
          ],
          [],
        );

        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          title: ENCODED_FILE_PATHS_TITLE,
          message: ENCODED_FILE_PATHS_MESSAGE,
          dismissible: false,
        });
      });
    });

    describe('on a 404 response', () => {
      let dismissAlert;

      beforeAll(() => {
        dismissAlert = jest.fn();

        mock.onGet(endpointMetadata).reply(HTTP_STATUS_NOT_FOUND);
        createAlert.mockImplementation(() => ({ dismiss: dismissAlert }));
      });

      it('should show a warning', async () => {
        await testAction(
          diffActions.fetchDiffFilesMeta,
          {},
          { endpointMetadata, diffViewType: 'inline', showWhitespace: true },
          [{ type: types.SET_LOADING, payload: true }],
          [],
        );

        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({
          message: BUILDING_YOUR_MR,
          variant: 'warning',
        });
      });

      it("should attempt to close the alert if the MR reports that it's been prepared", async () => {
        await testAction(
          diffActions.fetchDiffFilesMeta,
          {},
          { endpointMetadata, diffViewType: 'inline', showWhitespace: true },
          [{ type: types.SET_LOADING, payload: true }],
          [],
        );

        diffsEventHub.$emit(EVT_MR_PREPARED);

        expect(dismissAlert).toHaveBeenCalled();
      });
    });

    it('should show no warning on any other status code', async () => {
      mock.onGet(endpointMetadata).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      try {
        await testAction(
          diffActions.fetchDiffFilesMeta,
          {},
          { endpointMetadata, diffViewType: 'inline', showWhitespace: true },
          [{ type: types.SET_LOADING, payload: true }],
          [],
        );
      } catch (error) {
        expect(error.response.status).toBe(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      }

      expect(createAlert).not.toHaveBeenCalled();
    });
  });

  describe('prefetchFileNeighbors', () => {
    it('dispatches two requests to prefetch the next/previous files', () => {
      return testAction(
        diffActions.prefetchFileNeighbors,
        {},
        {
          currentDiffIndex: 0,
          flatBlobsList: [
            {
              type: 'blob',
              fileHash: 'abc',
            },
            {
              type: 'blob',
              fileHash: 'def',
            },
            {
              type: 'blob',
              fileHash: 'ghi',
            },
          ],
        },
        [],
        [
          { type: 'prefetchSingleFile', payload: { type: 'blob', fileHash: 'def' } },
          { type: 'prefetchSingleFile', payload: { type: 'blob', fileHash: 'abc' } },
        ],
      );
    });
  });

  describe('fetchCoverageFiles', () => {
    const endpointCoverage = '/fetch';

    it('should commit SET_COVERAGE_DATA with received response', () => {
      const data = { files: { 'app.js': { 1: 0, 2: 1 } } };

      mock.onGet(endpointCoverage).reply(HTTP_STATUS_OK, { data });

      return testAction(
        diffActions.fetchCoverageFiles,
        {},
        { endpointCoverage },
        [{ type: types.SET_COVERAGE_DATA, payload: { data } }],
        [],
      );
    });

    it('should show alert on API error', async () => {
      mock.onGet(endpointCoverage).reply(HTTP_STATUS_BAD_REQUEST);

      await testAction(diffActions.fetchCoverageFiles, {}, { endpointCoverage }, [], []);
      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(createAlert).toHaveBeenCalledWith({
        message: SOMETHING_WENT_WRONG,
      });
    });
  });

  describe('setHighlightedRow', () => {
    it('should mark currently selected diff and set lineHash and fileHash of highlightedRow', () => {
      return testAction(diffActions.setHighlightedRow, { lineCode: 'ABC_123' }, {}, [
        { type: types.SET_HIGHLIGHTED_ROW, payload: 'ABC_123' },
        { type: types.SET_CURRENT_DIFF_FILE, payload: 'ABC' },
      ]);
    });

    it('should prevent default event', () => {
      const preventDefault = jest.fn();
      const target = { href: TEST_HOST };
      const event = { target, preventDefault };
      testAction(diffActions.setHighlightedRow, { lineCode: 'ABC_123', event }, {}, [
        { type: types.SET_HIGHLIGHTED_ROW, payload: 'ABC_123' },
        { type: types.SET_CURRENT_DIFF_FILE, payload: 'ABC' },
      ]);
      expect(preventDefault).toHaveBeenCalled();
    });

    it('should filter out linked file param', () => {
      const target = { href: `${TEST_HOST}/diffs?file=foo#abc_11` };
      const event = { target, preventDefault: jest.fn() };
      testAction(diffActions.setHighlightedRow, { lineCode: 'ABC_123', event }, {}, [
        { type: types.SET_HIGHLIGHTED_ROW, payload: 'ABC_123' },
        { type: types.SET_CURRENT_DIFF_FILE, payload: 'ABC' },
      ]);
      expect(window.location.href).toBe(`${TEST_HOST}/diffs#abc_11`);
    });
  });

  describe('assignDiscussionsToDiff', () => {
    afterEach(() => {
      window.location.hash = '';
    });

    it('should merge discussions into diffs', () => {
      window.location.hash = 'ABC_123';

      const state = {
        diffFiles: [
          {
            file_hash: 'ABC',
            parallel_diff_lines: [
              {
                left: {
                  line_code: 'ABC_1_1',
                  discussions: [],
                },
                right: {
                  line_code: 'ABC_1_1',
                  discussions: [],
                },
              },
            ],
            highlighted_diff_lines: [
              {
                line_code: 'ABC_1_1',
                discussions: [],
                old_line: 5,
                new_line: null,
              },
            ],
            diff_refs: {
              base_sha: 'abc',
              head_sha: 'def',
              start_sha: 'ghi',
            },
            new_path: 'file1',
            old_path: 'file2',
          },
        ],
      };

      const diffPosition = {
        base_sha: 'abc',
        head_sha: 'def',
        start_sha: 'ghi',
        new_line: null,
        new_path: 'file1',
        old_line: 5,
        old_path: 'file2',
      };

      const singleDiscussion = {
        line_code: 'ABC_1_1',
        diff_discussion: {},
        diff_file: {
          file_hash: 'ABC',
        },
        file_hash: 'ABC',
        resolvable: true,
        position: diffPosition,
        original_position: diffPosition,
      };

      const discussions = [singleDiscussion];

      return testAction(
        diffActions.assignDiscussionsToDiff,
        discussions,
        state,
        [
          {
            type: types.SET_LINE_DISCUSSIONS_FOR_FILE,
            payload: {
              discussion: singleDiscussion,
              diffPositionByLineCode: {
                ABC_1_1: {
                  base_sha: 'abc',
                  head_sha: 'def',
                  start_sha: 'ghi',
                  new_line: null,
                  new_path: 'file1',
                  old_line: 5,
                  old_path: 'file2',
                  line_range: null,
                  line_code: 'ABC_1_1',
                  position_type: 'text',
                },
              },
              hash: 'ABC_123',
            },
          },
        ],
        [],
      );
    });

    it('dispatches setCurrentDiffFileIdFromNote with note ID', () => {
      window.location.hash = 'note_123';

      return testAction(
        diffActions.assignDiscussionsToDiff,
        [],
        { diffFiles: [], flatBlobsList: [] },
        [],
        [{ type: 'setCurrentDiffFileIdFromNote', payload: '123' }],
      );
    });
  });

  describe('removeDiscussionsFromDiff', () => {
    it('does not call mutation if no diff file is on discussion', () => {
      testAction(
        diffActions.removeDiscussionsFromDiff,
        {
          id: '1',
          line_code: 'ABC_1_1',
        },
        {},
        [],
        [],
      );
    });

    it('should remove discussions from diffs', () => {
      const state = {
        diffFiles: [
          {
            file_hash: 'ABC',
            parallel_diff_lines: [
              {
                left: {
                  line_code: 'ABC_1_1',
                  discussions: [
                    {
                      id: 1,
                    },
                  ],
                },
                right: {
                  line_code: 'ABC_1_1',
                  discussions: [],
                },
              },
            ],
            highlighted_diff_lines: [
              {
                line_code: 'ABC_1_1',
                discussions: [],
              },
            ],
          },
        ],
      };
      const singleDiscussion = {
        id: '1',
        diff_file: { file_hash: 'ABC' },
        line_code: 'ABC_1_1',
      };

      return testAction(
        diffActions.removeDiscussionsFromDiff,
        singleDiscussion,
        state,
        [
          {
            type: types.REMOVE_LINE_DISCUSSIONS_FOR_FILE,
            payload: {
              id: '1',
              fileHash: 'ABC',
              lineCode: 'ABC_1_1',
            },
          },
        ],
        [],
      );
    });
  });

  describe('setDiffViewType', () => {
    it.each([['inline'], ['parallel']])(
      'should set the diff view type to $p and set the cookie',
      async (diffViewType) => {
        await testAction(
          diffActions.setDiffViewType,
          diffViewType,
          {},
          [{ type: types.SET_DIFF_VIEW_TYPE, payload: diffViewType }],
          [],
        );
        expect(window.location.toString()).toContain(`?view=${diffViewType}`);
        expect(Cookies.get(DIFF_VIEW_COOKIE_NAME)).toEqual(diffViewType);
      },
    );
  });

  describe('showCommentForm', () => {
    it('should call mutation to show comment form', () => {
      const payload = { lineCode: 'lineCode', fileHash: 'hash' };

      return testAction(
        diffActions.showCommentForm,
        payload,
        {},
        [{ type: types.TOGGLE_LINE_HAS_FORM, payload: { ...payload, hasForm: true } }],
        [],
      );
    });
  });

  describe('cancelCommentForm', () => {
    it('should call mutation to cancel comment form', () => {
      const payload = { lineCode: 'lineCode', fileHash: 'hash' };

      return testAction(
        diffActions.cancelCommentForm,
        payload,
        {},
        [{ type: types.TOGGLE_LINE_HAS_FORM, payload: { ...payload, hasForm: false } }],
        [],
      );
    });
  });

  describe('loadMoreLines', () => {
    it('should call mutation to show comment form', () => {
      const endpoint = '/diffs/load/more/lines';
      const params = { since: 6, to: 26 };
      const lineNumbers = { oldLineNumber: 3, newLineNumber: 5 };
      const fileHash = 'ff9200';
      const isExpandDown = false;
      const nextLineNumbers = {};
      const options = { endpoint, params, lineNumbers, fileHash, isExpandDown, nextLineNumbers };
      const contextLines = { contextLines: [{ lineCode: 6 }] };
      mock.onGet(endpoint).reply(HTTP_STATUS_OK, contextLines);

      return testAction(
        diffActions.loadMoreLines,
        options,
        {},
        [
          {
            type: types.ADD_CONTEXT_LINES,
            payload: { lineNumbers, contextLines, params, fileHash, isExpandDown, nextLineNumbers },
          },
        ],
        [],
      );
    });
  });

  describe('loadCollapsedDiff', () => {
    const state = { showWhitespace: true };
    it('should fetch data and call mutation with response and the give parameter', () => {
      const file = { hash: 123, load_collapsed_diff_url: '/load/collapsed/diff/url' };
      const data = { hash: 123, parallelDiffLines: [{ lineCode: 1 }] };
      const commit = jest.fn();
      mock.onGet(file.loadCollapsedDiffUrl).reply(HTTP_STATUS_OK, data);

      return diffActions
        .loadCollapsedDiff({ commit, getters: { commitId: null }, state }, { file })
        .then(() => {
          expect(commit).toHaveBeenCalledWith(types.ADD_COLLAPSED_DIFFS, { file, data });
        });
    });

    it('should fetch data without commit ID', () => {
      const file = { load_collapsed_diff_url: '/load/collapsed/diff/url' };
      const getters = {
        commitId: null,
      };

      jest.spyOn(axios, 'get').mockReturnValue(Promise.resolve({ data: {} }));

      diffActions.loadCollapsedDiff({ commit() {}, getters, state }, { file });

      expect(axios.get).toHaveBeenCalledWith(file.load_collapsed_diff_url, {
        params: { commit_id: null, w: '0' },
      });
    });

    it('should pass through params', () => {
      const file = { load_collapsed_diff_url: '/load/collapsed/diff/url' };
      const getters = {
        commitId: null,
      };

      jest.spyOn(axios, 'get').mockReturnValue(Promise.resolve({ data: {} }));

      diffActions.loadCollapsedDiff({ commit() {}, getters, state }, { file, params: { w: '1' } });

      expect(axios.get).toHaveBeenCalledWith(file.load_collapsed_diff_url, {
        params: { commit_id: null, w: '1' },
      });
    });

    it('should fetch data with commit ID', () => {
      const file = { load_collapsed_diff_url: '/load/collapsed/diff/url' };
      const getters = {
        commitId: '123',
      };

      jest.spyOn(axios, 'get').mockReturnValue(Promise.resolve({ data: {} }));

      diffActions.loadCollapsedDiff({ commit() {}, getters, state }, { file });

      expect(axios.get).toHaveBeenCalledWith(file.load_collapsed_diff_url, {
        params: { commit_id: '123', w: '0' },
      });
    });

    describe('version parameters', () => {
      const diffId = '4';
      const startSha = 'abc';
      const pathRoot = 'a/a/-/merge_requests/1';
      let file;
      let getters;

      beforeAll(() => {
        file = { load_collapsed_diff_url: '/load/collapsed/diff/url' };
        getters = {};
      });

      beforeEach(() => {
        jest.spyOn(axios, 'get').mockReturnValue(Promise.resolve({ data: {} }));
      });

      it('fetches the data when there is no mergeRequestDiff', () => {
        diffActions.loadCollapsedDiff({ commit() {}, getters, state }, { file });

        expect(axios.get).toHaveBeenCalledWith(file.load_collapsed_diff_url, {
          params: expect.any(Object),
        });
      });

      it.each`
        desc                                   | versionPath                                              | start_sha    | diff_id
        ${'no additional version information'} | ${`${pathRoot}?search=terms`}                            | ${undefined} | ${undefined}
        ${'the diff_id'}                       | ${`${pathRoot}?diff_id=${diffId}`}                       | ${undefined} | ${diffId}
        ${'the start_sha'}                     | ${`${pathRoot}?start_sha=${startSha}`}                   | ${startSha}  | ${undefined}
        ${'all available version information'} | ${`${pathRoot}?diff_id=${diffId}&start_sha=${startSha}`} | ${startSha}  | ${diffId}
      `('fetches the data and includes $desc', ({ versionPath, start_sha, diff_id }) => {
        jest.spyOn(axios, 'get').mockReturnValue(Promise.resolve({ data: {} }));

        diffActions.loadCollapsedDiff(
          { commit() {}, getters, state: { mergeRequestDiff: { version_path: versionPath } } },
          { file },
        );

        expect(axios.get).toHaveBeenCalledWith(file.load_collapsed_diff_url, {
          params: expect.objectContaining({ start_sha, diff_id }),
        });
      });
    });
  });

  describe('scrollToLineIfNeededInline', () => {
    const lineMock = {
      line_code: 'ABC_123',
    };

    it('should not call handleLocationHash when there is not hash', () => {
      window.location.hash = '';

      diffActions.scrollToLineIfNeededInline({}, lineMock);

      expect(commonUtils.handleLocationHash).not.toHaveBeenCalled();
    });

    it('should not call handleLocationHash when the hash does not match any line', () => {
      window.location.hash = 'XYZ_456';

      diffActions.scrollToLineIfNeededInline({}, lineMock);

      expect(commonUtils.handleLocationHash).not.toHaveBeenCalled();
    });

    it('should call handleLocationHash only when the hash matches a line', () => {
      window.location.hash = 'ABC_123';

      diffActions.scrollToLineIfNeededInline(
        {},
        {
          lineCode: 'ABC_456',
        },
      );
      diffActions.scrollToLineIfNeededInline({}, lineMock);
      diffActions.scrollToLineIfNeededInline(
        {},
        {
          lineCode: 'XYZ_456',
        },
      );

      expect(commonUtils.handleLocationHash).toHaveBeenCalled();
      expect(commonUtils.handleLocationHash).toHaveBeenCalledTimes(1);
    });
  });

  describe('scrollToLineIfNeededParallel', () => {
    const lineMock = {
      left: null,
      right: {
        line_code: 'ABC_123',
      },
    };

    it('should not call handleLocationHash when there is not hash', () => {
      window.location.hash = '';

      diffActions.scrollToLineIfNeededParallel({}, lineMock);

      expect(commonUtils.handleLocationHash).not.toHaveBeenCalled();
    });

    it('should not call handleLocationHash when the hash does not match any line', () => {
      window.location.hash = 'XYZ_456';

      diffActions.scrollToLineIfNeededParallel({}, lineMock);

      expect(commonUtils.handleLocationHash).not.toHaveBeenCalled();
    });

    it('should call handleLocationHash only when the hash matches a line', () => {
      window.location.hash = 'ABC_123';

      diffActions.scrollToLineIfNeededParallel(
        {},
        {
          left: null,
          right: {
            lineCode: 'ABC_456',
          },
        },
      );
      diffActions.scrollToLineIfNeededParallel({}, lineMock);
      diffActions.scrollToLineIfNeededParallel(
        {},
        {
          left: null,
          right: {
            lineCode: 'XYZ_456',
          },
        },
      );

      expect(commonUtils.handleLocationHash).toHaveBeenCalled();
      expect(commonUtils.handleLocationHash).toHaveBeenCalledTimes(1);
    });
  });

  describe('saveDiffDiscussion', () => {
    const dispatch = jest.fn((name) => {
      switch (name) {
        case 'saveNote':
          return Promise.resolve({
            discussion: 'test',
          });
        case 'updateDiscussion':
          return Promise.resolve('discussion');
        default:
          return Promise.resolve({});
      }
    });

    const commitId = 'something';
    const formData = {
      diffFile: getDiffFileMock(),
      noteableData: {},
    };
    const note = '';
    const state = {
      commit: {
        id: commitId,
      },
    };

    it('dispatches actions', () => {
      return diffActions.saveDiffDiscussion({ state, dispatch }, { note, formData }).then(() => {
        expect(dispatch).toHaveBeenCalledTimes(5);
        expect(dispatch).toHaveBeenNthCalledWith(1, 'saveNote', expect.any(Object), {
          root: true,
        });

        const postData = dispatch.mock.calls[0][1];
        expect(postData.data.note.commit_id).toBe(commitId);

        expect(dispatch).toHaveBeenNthCalledWith(2, 'updateDiscussion', 'test', { root: true });
        expect(dispatch).toHaveBeenNthCalledWith(3, 'assignDiscussionsToDiff', ['discussion']);
      });
    });

    it('should not allow adding note with sensitive token', async () => {
      const sensitiveMessage = 'token: glpat-1234567890abcdefghij';

      await diffActions.saveDiffDiscussion(
        { state, dispatch },
        { note: sensitiveMessage, formData },
      );
      expect(dispatch).not.toHaveBeenCalled();
      expect(confirmAction).toHaveBeenCalledWith(
        '',
        expect.objectContaining({
          title: 'Warning: Potential secret detected',
        }),
      );
    });
  });

  describe('toggleTreeOpen', () => {
    it('commits TOGGLE_FOLDER_OPEN', () => {
      return testAction(
        diffActions.toggleTreeOpen,
        'path',
        {},
        [{ type: types.TOGGLE_FOLDER_OPEN, payload: 'path' }],
        [],
      );
    });
  });

  describe('setTreeOpen', () => {
    it('commits SET_FOLDER_OPEN', () => {
      return testAction(
        diffActions.setTreeOpen,
        { path: 'path', opened: true },
        {},
        [{ type: types.SET_FOLDER_OPEN, payload: { path: 'path', opened: true } }],
        [],
      );
    });
  });

  describe('goToFile', () => {
    const getters = {};
    const file = { path: 'path' };
    const fileHash = 'test';
    let state;
    let dispatch;
    let commit;

    beforeEach(() => {
      getters.isTreePathLoaded = () => false;
      state = {
        viewDiffsFileByFile: true,
        treeEntries: {
          path: {
            fileHash,
          },
        },
      };
      commit = jest.fn();
      dispatch = jest.fn().mockResolvedValue();
    });

    it('immediately defers to scrollToFile if the app is not in file-by-file mode', () => {
      state.viewDiffsFileByFile = false;

      diffActions.goToFile({ state, dispatch }, file);

      expect(dispatch).toHaveBeenCalledWith('scrollToFile', file);
    });

    describe('when the app is in fileByFile mode', () => {
      it('commits SET_CURRENT_DIFF_FILE', () => {
        diffActions.goToFile({ state, commit, dispatch, getters }, file);

        expect(commit).toHaveBeenCalledWith(types.SET_CURRENT_DIFF_FILE, fileHash);
      });

      it('does nothing more if the path has already been loaded', () => {
        getters.isTreePathLoaded = () => true;

        diffActions.goToFile({ state, dispatch, getters, commit }, file);

        expect(commit).toHaveBeenCalledWith(types.SET_CURRENT_DIFF_FILE, fileHash);
        expect(dispatch).not.toHaveBeenCalledWith('fetchFileByFile');
      });

      describe('when the tree entry has not been loaded', () => {
        it('updates location hash', () => {
          diffActions.goToFile({ state, commit, getters, dispatch }, file);

          expect(historyPushState).toHaveBeenCalledWith(new URL(`${TEST_HOST}#test`), {
            skipScrolling: true,
          });
          expect(scrollToElement).toHaveBeenCalledWith('.diff-files-holder', { duration: 0 });
        });

        it('loads the file and then scrolls to it', async () => {
          diffActions.goToFile({ state, commit, getters, dispatch }, file);

          // Wait for the fetchFileByFile dispatch to return, to trigger scrollToFile
          await waitForPromises();

          expect(dispatch).toHaveBeenCalledWith('fetchFileByFile');
          expect(commonUtils.historyPushState).toHaveBeenCalledWith(new URL(`${TEST_HOST}/#test`), {
            skipScrolling: true,
          });
          expect(commonUtils.scrollToElement).toHaveBeenCalledWith('.diff-files-holder', {
            duration: 0,
          });
          expect(dispatch).toHaveBeenCalledWith('fetchFileByFile');
        });

        it('unlink the file', () => {
          diffActions.goToFile({ state, commit, getters, dispatch }, file);
          expect(dispatch).toHaveBeenCalledWith('unlinkFile');
        });
      });
    });
  });

  describe('scrollToFile', () => {
    let commit;
    const getters = { isVirtualScrollingEnabled: false };

    beforeEach(() => {
      commit = jest.fn();
    });

    it('updates location hash', () => {
      const state = {
        treeEntries: {
          path: {
            fileHash: 'test',
          },
        },
      };

      diffActions.scrollToFile({ state, commit, getters }, { path: 'path' });

      expect(document.location.hash).toBe('#test');
    });

    it('commits SET_CURRENT_DIFF_FILE', () => {
      const state = {
        treeEntries: {
          path: {
            fileHash: 'test',
          },
        },
      };

      diffActions.scrollToFile({ state, commit, getters }, { path: 'path' });

      expect(commit).toHaveBeenCalledWith(types.SET_CURRENT_DIFF_FILE, 'test');
    });
  });

  describe('setShowTreeList', () => {
    it('commits toggle', () => {
      return testAction(
        diffActions.setShowTreeList,
        { showTreeList: true },
        {},
        [{ type: types.SET_SHOW_TREE_LIST, payload: true }],
        [],
      );
    });

    it('updates localStorage', () => {
      jest.spyOn(localStorage, 'setItem').mockImplementation(() => {});

      diffActions.setShowTreeList({ commit() {} }, { showTreeList: true });

      expect(localStorage.setItem).toHaveBeenCalledWith('mr_tree_show', true);
    });

    it('does not update localStorage', () => {
      jest.spyOn(localStorage, 'setItem').mockImplementation(() => {});

      diffActions.setShowTreeList({ commit() {} }, { showTreeList: true, saving: false });

      expect(localStorage.setItem).not.toHaveBeenCalled();
    });
  });

  describe('renderFileForDiscussionId', () => {
    const rootState = {
      notes: {
        discussions: [
          {
            id: '123',
            diff_file: {
              file_hash: 'HASH',
            },
          },
          {
            id: '456',
            diff_file: {
              file_hash: 'HASH',
            },
          },
        ],
      },
    };
    let commit;
    let $emit;
    const state = ({ collapsed, renderIt }) => ({
      diffFiles: [
        {
          file_hash: 'HASH',
          viewer: {
            automaticallyCollapsed: collapsed,
          },
          renderIt,
        },
      ],
    });

    beforeEach(() => {
      commit = jest.fn();
      $emit = jest.spyOn(eventHub, '$emit');
    });

    it('expands the file for the given discussion id', () => {
      const localState = state({ collapsed: true, renderIt: false });

      diffActions.renderFileForDiscussionId({ rootState, state: localState, commit }, '123');

      expect($emit).toHaveBeenCalledTimes(1);
      expect(commonUtils.scrollToElement).toHaveBeenCalledTimes(1);
    });

    it('jumps to discussion on already rendered and expanded file', () => {
      const localState = state({ collapsed: false, renderIt: true });

      diffActions.renderFileForDiscussionId({ rootState, state: localState, commit }, '123');

      expect(commit).not.toHaveBeenCalled();
      expect($emit).toHaveBeenCalledTimes(1);
      expect(commonUtils.scrollToElement).not.toHaveBeenCalled();
    });
  });

  describe('setRenderTreeList', () => {
    it('commits SET_RENDER_TREE_LIST', () => {
      return testAction(
        diffActions.setRenderTreeList,
        { renderTreeList: true },
        {},
        [{ type: types.SET_RENDER_TREE_LIST, payload: true }],
        [],
      );
    });

    it('sets localStorage', () => {
      diffActions.setRenderTreeList({ commit() {} }, { renderTreeList: true });

      expect(localStorage.setItem).toHaveBeenCalledWith('mr_diff_tree_list', true);
    });
  });

  describe('setShowWhitespace', () => {
    const endpointUpdateUser = 'user/prefs';
    let putSpy;

    beforeEach(() => {
      jest.spyOn(api, 'trackRedisHllUserEvent').mockImplementation(() => {});
      putSpy = jest.spyOn(axios, 'put');

      mock.onPut(endpointUpdateUser).reply(HTTP_STATUS_OK, {});
      jest.spyOn(eventHub, '$emit').mockImplementation();
    });

    it('commits SET_SHOW_WHITESPACE', () => {
      return testAction(
        diffActions.setShowWhitespace,
        { showWhitespace: true, updateDatabase: false },
        {},
        [{ type: types.SET_SHOW_WHITESPACE, payload: true }],
        [],
      );
    });

    it('saves to the database when the user is logged in', async () => {
      window.gon = { current_user_id: 12345 };

      await diffActions.setShowWhitespace(
        { state: { endpointUpdateUser }, commit() {} },
        { showWhitespace: true, updateDatabase: true },
      );

      expect(putSpy).toHaveBeenCalledWith(endpointUpdateUser, { show_whitespace_in_diffs: true });
    });

    it('does not try to save to the API if the user is not logged in', async () => {
      window.gon = {};

      await diffActions.setShowWhitespace(
        { state: { endpointUpdateUser }, commit() {} },
        { showWhitespace: true, updateDatabase: true },
      );

      expect(putSpy).not.toHaveBeenCalled();
    });

    it('emits eventHub event', async () => {
      await diffActions.setShowWhitespace(
        { state: {}, commit() {} },
        { showWhitespace: true, updateDatabase: false },
      );

      expect(eventHub.$emit).toHaveBeenCalledWith('refetchDiffData');
    });
  });

  describe('receiveFullDiffError', () => {
    it('updates state with the file that did not load', () => {
      return testAction(
        diffActions.receiveFullDiffError,
        'file',
        {},
        [{ type: types.RECEIVE_FULL_DIFF_ERROR, payload: 'file' }],
        [],
      );
    });
  });

  describe('fetchFullDiff', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/context`).replyOnce(HTTP_STATUS_OK, ['test']);
      });

      it('commits the success and dispatches an action to expand the new lines', () => {
        const file = {
          context_lines_path: `${TEST_HOST}/context`,
          file_path: 'test',
          file_hash: 'test',
        };
        return testAction(
          diffActions.fetchFullDiff,
          file,
          null,
          [{ type: types.RECEIVE_FULL_DIFF_SUCCESS, payload: { filePath: 'test' } }],
          [{ type: 'setExpandedDiffLines', payload: { file, data: ['test'] } }],
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${TEST_HOST}/context`).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      });

      it('dispatches receiveFullDiffError', () => {
        return testAction(
          diffActions.fetchFullDiff,
          { context_lines_path: `${TEST_HOST}/context`, file_path: 'test', file_hash: 'test' },
          null,
          [],
          [{ type: 'receiveFullDiffError', payload: 'test' }],
        );
      });
    });
  });

  describe('toggleFullDiff', () => {
    let state;

    beforeEach(() => {
      state = {
        diffFiles: [{ file_path: 'test', isShowingFullFile: false }],
      };
    });

    it('dispatches fetchFullDiff when file is not expanded', () => {
      return testAction(
        diffActions.toggleFullDiff,
        'test',
        state,
        [{ type: types.REQUEST_FULL_DIFF, payload: 'test' }],
        [{ type: 'fetchFullDiff', payload: state.diffFiles[0] }],
      );
    });
  });

  describe('switchToFullDiffFromRenamedFile', () => {
    const SUCCESS_URL = 'fakehost/context.success';
    const testFilePath = 'testpath';
    const updatedViewerName = 'testviewer';
    const preparedLine = { prepared: 'in-a-test' };
    const testFile = {
      file_path: testFilePath,
      file_hash: 'testhash',
      alternate_viewer: { name: updatedViewerName },
    };
    const updatedViewer = {
      name: updatedViewerName,
      automaticallyCollapsed: false,
      manuallyCollapsed: false,
      forceOpen: false,
    };
    const testData = [{ rich_text: 'test' }, { rich_text: 'file2' }];
    let renamedFile;

    beforeEach(() => {
      jest.spyOn(utils, 'prepareLineForRenamedFile').mockImplementation(() => preparedLine);
    });

    afterEach(() => {
      renamedFile = null;
    });

    describe('success', () => {
      beforeEach(() => {
        renamedFile = { ...testFile, context_lines_path: SUCCESS_URL };
        mock.onGet(SUCCESS_URL).replyOnce(HTTP_STATUS_OK, testData);
      });

      it.each`
        diffViewType
        ${INLINE_DIFF_VIEW_TYPE}
        ${PARALLEL_DIFF_VIEW_TYPE}
      `(
        'performs the correct mutations and starts a render queue for view type $diffViewType',
        ({ diffViewType }) => {
          return testAction(
            diffActions.switchToFullDiffFromRenamedFile,
            { diffFile: renamedFile },
            { diffViewType },
            [
              {
                type: types.SET_DIFF_FILE_VIEWER,
                payload: { filePath: testFilePath, viewer: updatedViewer },
              },
              {
                type: types.SET_CURRENT_VIEW_DIFF_FILE_LINES,
                payload: { filePath: testFilePath, lines: [preparedLine, preparedLine] },
              },
            ],
            [],
          );
        },
      );
    });
  });

  describe('setFileCollapsedByUser', () => {
    it('commits SET_FILE_COLLAPSED', () => {
      return testAction(
        diffActions.setFileCollapsedByUser,
        { filePath: 'test', collapsed: true },
        null,
        [
          {
            type: types.SET_FILE_COLLAPSED,
            payload: { filePath: 'test', collapsed: true, trigger: 'manual' },
          },
        ],
        [],
      );
    });
  });

  describe('setFileForcedOpen', () => {
    it('commits SET_FILE_FORCED_OPEN', () => {
      return testAction(diffActions.setFileForcedOpen, { filePath: 'test', forced: true }, null, [
        {
          type: types.SET_FILE_FORCED_OPEN,
          payload: { filePath: 'test', forced: true },
        },
      ]);
    });
  });

  describe('setExpandedDiffLines', () => {
    beforeEach(() => {
      utils.idleCallback.mockImplementation((cb) => {
        cb({ timeRemaining: () => 50 });
      });
    });

    it('commits SET_CURRENT_VIEW_DIFF_FILE_LINES when lines less than MAX_RENDERING_DIFF_LINES', () => {
      utils.convertExpandLines.mockImplementation(() => ['test']);

      return testAction(
        diffActions.setExpandedDiffLines,
        { file: { file_path: 'path' }, data: [] },
        { diffViewType: 'inline' },
        [
          {
            type: 'SET_CURRENT_VIEW_DIFF_FILE_LINES',
            payload: { filePath: 'path', lines: ['test'] },
          },
        ],
        [],
      );
    });

    it('commits ADD_CURRENT_VIEW_DIFF_FILE_LINES when lines more than MAX_RENDERING_DIFF_LINES', () => {
      const lines = new Array(501).fill().map((_, i) => `line-${i}`);
      utils.convertExpandLines.mockReturnValue(lines);

      return testAction(
        diffActions.setExpandedDiffLines,
        { file: { file_path: 'path' }, data: [] },
        { diffViewType: 'inline' },
        [
          {
            type: 'SET_CURRENT_VIEW_DIFF_FILE_LINES',
            payload: { filePath: 'path', lines: lines.slice(0, 200) },
          },
          { type: 'TOGGLE_DIFF_FILE_RENDERING_MORE', payload: 'path' },
          ...new Array(301).fill().map((_, i) => ({
            type: 'ADD_CURRENT_VIEW_DIFF_FILE_LINES',
            payload: { filePath: 'path', line: `line-${i + 200}` },
          })),
          { type: 'TOGGLE_DIFF_FILE_RENDERING_MORE', payload: 'path' },
        ],
        [],
      );
    });
  });

  describe('setSuggestPopoverDismissed', () => {
    it('commits SET_SHOW_SUGGEST_POPOVER', async () => {
      const state = { dismissEndpoint: `${TEST_HOST}/-/user_callouts` };
      mock.onPost(state.dismissEndpoint).reply(HTTP_STATUS_OK, {});

      jest.spyOn(axios, 'post');

      await testAction(
        diffActions.setSuggestPopoverDismissed,
        null,
        state,
        [{ type: types.SET_SHOW_SUGGEST_POPOVER }],
        [],
      );
      expect(axios.post).toHaveBeenCalledWith(state.dismissEndpoint, {
        feature_name: 'suggest_popover_dismissed',
      });
    });
  });

  describe('changeCurrentCommit', () => {
    it('commits the new commit information and re-requests the diff metadata for the commit', () => {
      return testAction(
        diffActions.changeCurrentCommit,
        { commitId: 'NEW' },
        {
          commit: {
            id: 'OLD',
          },
          endpoint: 'URL/OLD',
          endpointBatch: 'URL/OLD',
          endpointMetadata: 'URL/OLD',
        },
        [
          { type: types.SET_DIFF_FILES, payload: [] },
          {
            type: types.SET_BASE_CONFIG,
            payload: {
              commit: {
                id: 'OLD', // Not a typo: the action fired next will overwrite all of the `commit` in state
              },
              endpoint: 'URL/NEW',
              endpointBatch: 'URL/NEW',
              endpointMetadata: 'URL/NEW',
            },
          },
        ],
        [{ type: 'fetchDiffFilesMeta' }],
      );
    });

    it.each`
      commitId     | commit           | msg
      ${undefined} | ${{ id: 'OLD' }} | ${'`commitId` is a required argument'}
      ${'NEW'}     | ${null}          | ${'`state` must already contain a valid `commit`'}
      ${undefined} | ${null}          | ${'`commitId` is a required argument'}
    `(
      'returns a rejected promise with the error message $msg given `{ "commitId": $commitId, "state.commit": $commit }`',
      ({ commitId, commit, msg }) => {
        const err = new Error(msg);
        const actionReturn = testAction(
          diffActions.changeCurrentCommit,
          { commitId },
          {
            endpoint: 'URL/OLD',
            endpointBatch: 'URL/OLD',
            endpointMetadata: 'URL/OLD',
            commit,
          },
          [],
          [],
        );

        return expect(actionReturn).rejects.toStrictEqual(err);
      },
    );
  });

  describe('moveToNeighboringCommit', () => {
    it.each`
      direction     | expected         | currentCommit
      ${'next'}     | ${'NEXTSHA'}     | ${{ next_commit_id: 'NEXTSHA' }}
      ${'previous'} | ${'PREVIOUSSHA'} | ${{ prev_commit_id: 'PREVIOUSSHA' }}
    `(
      'for the direction "$direction", dispatches the action to move to the SHA "$expected"',
      ({ direction, expected, currentCommit }) => {
        return testAction(
          diffActions.moveToNeighboringCommit,
          { direction },
          { commit: currentCommit },
          [],
          [{ type: 'changeCurrentCommit', payload: { commitId: expected } }],
        );
      },
    );

    it.each`
      direction     | diffsAreLoading | currentCommit
      ${'next'}     | ${false}        | ${{ prev_commit_id: 'PREVIOUSSHA' }}
      ${'next'}     | ${true}         | ${{ prev_commit_id: 'PREVIOUSSHA' }}
      ${'next'}     | ${false}        | ${undefined}
      ${'previous'} | ${false}        | ${{ next_commit_id: 'NEXTSHA' }}
      ${'previous'} | ${true}         | ${{ next_commit_id: 'NEXTSHA' }}
      ${'previous'} | ${false}        | ${undefined}
    `(
      'given `{ "isloading": $diffsAreLoading, "commit": $currentCommit }` in state, no actions are dispatched',
      ({ direction, diffsAreLoading, currentCommit }) => {
        return testAction(
          diffActions.moveToNeighboringCommit,
          { direction },
          { commit: currentCommit, isLoading: diffsAreLoading },
          [],
          [],
        );
      },
    );
  });

  describe('rereadNoteHash', () => {
    beforeEach(() => {
      window.location.hash = 'note_123';
    });

    it('dispatches setCurrentDiffFileIdFromNote if the hash is a note URL', () => {
      window.location.hash = 'note_123';

      return testAction(
        diffActions.rereadNoteHash,
        {},
        {},
        [],
        [{ type: 'setCurrentDiffFileIdFromNote', payload: '123' }],
      );
    });

    it('dispatches fetchFileByFile if the app is in fileByFile mode', () => {
      window.location.hash = 'note_123';

      return testAction(
        diffActions.rereadNoteHash,
        {},
        { viewDiffsFileByFile: true },
        [],
        [{ type: 'setCurrentDiffFileIdFromNote', payload: '123' }, { type: 'fetchFileByFile' }],
      );
    });

    it('does not try to fetch the diff file if the app is not in fileByFile mode', () => {
      window.location.hash = 'note_123';

      return testAction(
        diffActions.rereadNoteHash,
        {},
        { viewDiffsFileByFile: false },
        [],
        [{ type: 'setCurrentDiffFileIdFromNote', payload: '123' }],
      );
    });

    it('does nothing if the hash is not a note URL', () => {
      window.location.hash = 'abcdef1234567890';

      return testAction(diffActions.rereadNoteHash, {}, {}, [], []);
    });
  });

  describe('setCurrentDiffFileIdFromNote', () => {
    it('commits SET_CURRENT_DIFF_FILE', () => {
      const commit = jest.fn();
      const getters = { flatBlobsList: [{ fileHash: '123' }] };
      const rootGetters = {
        getDiscussion: () => ({ diff_file: { file_hash: '123' } }),
        notesById: { 1: { discussion_id: '2' } },
      };

      diffActions.setCurrentDiffFileIdFromNote({ commit, getters, rootGetters }, '1');

      expect(commit).toHaveBeenCalledWith(types.SET_CURRENT_DIFF_FILE, '123');
    });

    it('does not commit SET_CURRENT_DIFF_FILE when discussion has no diff_file', () => {
      const commit = jest.fn();
      const rootGetters = {
        getDiscussion: () => ({ id: '1' }),
        notesById: { 1: { discussion_id: '2' } },
      };

      diffActions.setCurrentDiffFileIdFromNote({ commit, rootGetters }, '1');

      expect(commit).not.toHaveBeenCalled();
    });

    it('does not commit SET_CURRENT_DIFF_FILE when diff file does not exist', () => {
      const commit = jest.fn();
      const getters = { flatBlobsList: [{ fileHash: '123' }] };
      const rootGetters = {
        getDiscussion: () => ({ diff_file: { file_hash: '124' } }),
        notesById: { 1: { discussion_id: '2' } },
      };

      diffActions.setCurrentDiffFileIdFromNote({ commit, getters, rootGetters }, '1');

      expect(commit).not.toHaveBeenCalled();
    });
  });

  describe('navigateToDiffFileIndex', () => {
    it('commits SET_CURRENT_DIFF_FILE', () => {
      return testAction(
        diffActions.navigateToDiffFileIndex,
        0,
        { flatBlobsList: [{ fileHash: '123' }] },
        [{ type: types.SET_CURRENT_DIFF_FILE, payload: '123' }],
        [{ type: 'unlinkFile' }],
      );
    });

    it('dispatches the fetchFileByFile action when the state value viewDiffsFileByFile is true', () => {
      return testAction(
        diffActions.navigateToDiffFileIndex,
        0,
        { viewDiffsFileByFile: true, flatBlobsList: [{ fileHash: '123' }] },
        [{ type: types.SET_CURRENT_DIFF_FILE, payload: '123' }],
        [{ type: 'unlinkFile' }, { type: 'fetchFileByFile' }],
      );
    });
  });

  describe('setFileByFile', () => {
    const updateUserEndpoint = 'user/prefs';
    let putSpy;

    beforeEach(() => {
      putSpy = jest.spyOn(axios, 'put');

      mock.onPut(updateUserEndpoint).reply(HTTP_STATUS_OK, {});
    });

    it.each`
      value
      ${true}
      ${false}
    `(
      'commits SET_FILE_BY_FILE and persists the File-by-File user preference with the new value $value',
      async ({ value }) => {
        await testAction(
          diffActions.setFileByFile,
          { fileByFile: value },
          {
            viewDiffsFileByFile: null,
            endpointUpdateUser: updateUserEndpoint,
          },
          [{ type: types.SET_FILE_BY_FILE, payload: value }],
          [],
        );

        expect(putSpy).toHaveBeenCalledWith(updateUserEndpoint, { view_diffs_file_by_file: value });
      },
    );
  });

  describe('reviewFile', () => {
    const file = {
      id: '123',
      file_hash: 'xyz',
      file_identifier_hash: 'abc',
      load_collapsed_diff_url: 'gitlab-org/gitlab-test/-/merge_requests/1/diffs',
    };
    it.each`
      reviews                         | diffFile | reviewed
      ${{ abc: ['123', 'hash:xyz'] }} | ${file}  | ${true}
      ${{}}                           | ${file}  | ${false}
    `(
      'sets reviews ($reviews) to localStorage and state for file $file if it is marked reviewed=$reviewed',
      ({ reviews, diffFile, reviewed }) => {
        const commitSpy = jest.fn();
        const getterSpy = jest.fn().mockReturnValue([]);

        diffActions.reviewFile(
          {
            commit: commitSpy,
            getters: {
              fileReviews: getterSpy,
            },
            state: {
              mrReviews: { abc: ['123'] },
            },
          },
          {
            file: diffFile,
            reviewed,
          },
        );

        expect(localStorage.setItem).toHaveBeenCalledTimes(1);
        expect(localStorage.setItem).toHaveBeenCalledWith(
          'gitlab-org/gitlab-test/-/merge_requests/1-file-reviews',
          JSON.stringify(reviews),
        );
        expect(commitSpy).toHaveBeenCalledWith(types.SET_MR_FILE_REVIEWS, reviews);
      },
    );
  });

  describe('toggleFileCommentForm', () => {
    it('commits TOGGLE_FILE_COMMENT_FORM', () => {
      const file = getDiffFileMock();
      return testAction(
        diffActions.toggleFileCommentForm,
        file.file_path,
        {
          diffFiles: [file],
        },
        [
          { type: types.TOGGLE_FILE_COMMENT_FORM, payload: file.file_path },
          {
            type: types.SET_FILE_COLLAPSED,
            payload: { filePath: file.file_path, collapsed: false },
          },
        ],
        [],
      );
    });

    it('always opens if file is collapsed', () => {
      const file = {
        ...getDiffFileMock(),
        viewer: {
          ...getDiffFileMock().viewer,
          manuallyCollapsed: true,
        },
      };
      return testAction(
        diffActions.toggleFileCommentForm,
        file.file_path,
        {
          diffFiles: [file],
        },
        [
          {
            type: types.SET_FILE_COMMENT_FORM,
            payload: { filePath: file.file_path, expanded: true },
          },
          {
            type: types.SET_FILE_COLLAPSED,
            payload: { filePath: file.file_path, collapsed: false },
          },
        ],
        [],
      );
    });
  });

  describe('addDraftToFile', () => {
    it('commits ADD_DRAFT_TO_FILE', () => {
      return testAction(
        diffActions.addDraftToFile,
        { filePath: 'path', draft: 'draft' },
        {},
        [{ type: types.ADD_DRAFT_TO_FILE, payload: { filePath: 'path', draft: 'draft' } }],
        [],
      );
    });
  });

  describe('fetchLinkedFile', () => {
    it('fetches linked file', async () => {
      const linkedFileHref = `${TEST_HOST}/linked-file`;
      const linkedFile = getDiffFileMock();
      const diffFiles = [linkedFile];
      const hubSpy = jest.spyOn(diffsEventHub, '$emit');
      mock.onGet(new RegExp(linkedFileHref)).reply(HTTP_STATUS_OK, { diff_files: diffFiles });

      await testAction(
        diffActions.fetchLinkedFile,
        linkedFileHref,
        {},
        [
          { type: types.SET_BATCH_LOADING_STATE, payload: 'loading' },
          { type: types.SET_RETRIEVING_BATCHES, payload: true },
          {
            type: types.SET_DIFF_DATA_BATCH,
            payload: { diff_files: diffFiles, updatePosition: false },
          },
          { type: types.SET_LINKED_FILE_HASH, payload: linkedFile.file_hash },
          { type: types.SET_CURRENT_DIFF_FILE, payload: linkedFile.file_hash },
          { type: types.SET_BATCH_LOADING_STATE, payload: 'loaded' },
          { type: types.SET_RETRIEVING_BATCHES, payload: false },
        ],
        [],
      );

      jest.runAllTimers();
      expect(hubSpy).toHaveBeenCalledWith('diffFilesModified');
      expect(handleLocationHash).toHaveBeenCalled();
    });

    it('handles load error', async () => {
      const linkedFileHref = `${TEST_HOST}/linked-file`;
      const hubSpy = jest.spyOn(diffsEventHub, '$emit');
      mock.onGet(new RegExp(linkedFileHref)).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      try {
        await testAction(
          diffActions.fetchLinkedFile,
          linkedFileHref,
          {},
          [
            { type: types.SET_BATCH_LOADING_STATE, payload: 'loading' },
            { type: types.SET_RETRIEVING_BATCHES, payload: true },
            { type: types.SET_BATCH_LOADING_STATE, payload: 'error' },
            { type: types.SET_RETRIEVING_BATCHES, payload: false },
          ],
          [],
        );
      } catch (error) {
        expect(error.response.status).toBe(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      }

      jest.runAllTimers();
      expect(hubSpy).not.toHaveBeenCalledWith('diffFilesModified');
      expect(handleLocationHash).not.toHaveBeenCalled();
    });

    it('fetches linked context lines', async () => {
      const linkedFile = getDiffFileMock();
      const diffFiles = [linkedFile];
      window.location.hash = `#${linkedFile.file_hash}_10_10`;
      const linkedFileHref = `${TEST_HOST}/linked-file`;
      jest.spyOn(diffsEventHub, '$emit');
      mock.onGet(new RegExp(linkedFileHref)).reply(HTTP_STATUS_OK, { diff_files: diffFiles });
      const dispatch = jest.fn();

      await diffActions.fetchLinkedFile({ dispatch, state: {}, commit: jest.fn() }, linkedFileHref);
      expect(dispatch).toHaveBeenCalledWith('fetchLinkedExpandedLine', {
        fileHash: linkedFile.file_hash,
        oldLine: 10,
        newLine: 10,
      });
    });
  });

  describe('unlinkFile', () => {
    it('unlinks linked file', () => {
      const linkedFile = getDiffFileMock();
      setWindowLocation(`${TEST_HOST}/?file=${linkedFile.file_hash}#${linkedFile.file_hash}_10_10`);
      testAction(
        diffActions.unlinkFile,
        undefined,
        { linkedFile },
        [{ type: types.SET_LINKED_FILE_HASH, payload: null }],
        [],
      );
      expect(window.location.hash).toBe('');
      expect(window.location.search).toBe('');
    });

    it('does nothing when no linked file present', () => {
      testAction(diffActions.unlinkFile, undefined, {}, [], []);
    });
  });

  describe('expandAllFiles', () => {
    it('triggers mutation', () => {
      testAction(
        diffActions.expandAllFiles,
        undefined,
        {},
        [
          {
            type: types.SET_COLLAPSED_STATE_FOR_ALL_FILES,
            payload: { collapsed: false },
          },
        ],
        [],
      );
    });
  });

  describe('collapseAllFiles', () => {
    it('triggers mutation', () => {
      testAction(
        diffActions.collapseAllFiles,
        undefined,
        {},
        [
          {
            type: types.SET_COLLAPSED_STATE_FOR_ALL_FILES,
            payload: { collapsed: true },
          },
        ],
        [],
      );
    });
  });

  describe('fetchLinkedExpandedLine', () => {
    it('does nothing when no linked file is present', () => {
      return testAction(
        diffActions.fetchLinkedExpandedLine,
        { fileHash: 'foo', oldLine: 10, newLine: 10 },
        { linkedFileHash: null },
        [],
        [],
      );
    });

    it("does nothing when fragment doesn't match linked file hash", () => {
      return testAction(
        diffActions.fetchLinkedExpandedLine,
        { fileHash: 'foo', oldLine: 10, newLine: 10 },
        { linkedFileHash: 'foobar' },
        [],
        [],
      );
    });

    it('does nothing when line is already present', () => {
      return testAction(
        diffActions.fetchLinkedExpandedLine,
        { fileHash: 'foo', oldLine: 10, newLine: 10 },
        {
          linkedFileHash: 'foo',
          diffFiles: [
            { file_hash: 'foo', highlighted_diff_lines: [{ old_line: 10, new_line: 10 }] },
          ],
        },
        [],
        [],
      );
    });

    it('propagates the error when fetching expanded line data', () => {
      const fakeError = new Error();
      const linkedFile = {
        file_hash: 'abc123',
        highlighted_diff_lines: [
          { new_line: 1, old_line: 1 },
          { meta_data: { old_pos: 2, new_pos: 2 } },
        ],
      };
      const dispatch = jest.fn().mockRejectedValue(fakeError);

      return diffActions
        .fetchLinkedExpandedLine(
          { getters: { linkedFile }, dispatch },
          { fileHash: linkedFile.file_hash, oldLine: 10, newLine: 10 },
        )
        .catch((error) => {
          expect(error).toBe(fakeError);
        });
    });

    it('expands lines at the very top', async () => {
      const linkedFile = {
        file_hash: 'abc123',
        context_lines_path: `${TEST_HOST}/linked-file`,
        highlighted_diff_lines: [
          { meta_data: { old_pos: 5, new_pos: 6 } },
          { old_line: 5, new_line: 6 },
        ],
      };
      const dispatch = jest.fn();

      await diffActions.fetchLinkedExpandedLine(
        { getters: { linkedFile }, dispatch },
        { fileHash: linkedFile.file_hash, oldLine: 1, newLine: 1 },
      );
      expect(dispatch).toHaveBeenCalledWith('loadMoreLines', {
        endpoint: linkedFile.context_lines_path,
        fileHash: linkedFile.file_hash,
        isExpandDown: false,
        lineNumbers: {
          oldLineNumber: 5,
          newLineNumber: 6,
        },
        params: {
          bottom: false,
          offset: 1,
          since: 1,
          to: 5,
          unfold: true,
        },
      });
    });

    it('expands lines upwards in the middle of the file', async () => {
      const linkedFile = {
        file_hash: 'abc123',
        context_lines_path: `${TEST_HOST}/linked-file`,
        highlighted_diff_lines: [
          { old_line: 5, new_line: 6 },
          { meta_data: { old_pos: 50, new_pos: 51 } },
          { old_line: 50, new_line: 51 },
        ],
      };
      const dispatch = jest.fn();

      await diffActions.fetchLinkedExpandedLine(
        { getters: { linkedFile }, dispatch },
        { fileHash: linkedFile.file_hash, oldLine: 45, newLine: 45 },
      );
      expect(dispatch).toHaveBeenCalledWith('loadMoreLines', {
        endpoint: linkedFile.context_lines_path,
        fileHash: linkedFile.file_hash,
        isExpandDown: false,
        lineNumbers: {
          oldLineNumber: 50,
          newLineNumber: 51,
        },
        params: {
          bottom: false,
          offset: 1,
          since: 45,
          to: 50,
          unfold: true,
        },
      });
    });

    it('expands lines in both directions', async () => {
      const linkedFile = {
        file_hash: 'abc123',
        context_lines_path: `${TEST_HOST}/linked-file`,
        highlighted_diff_lines: [
          { old_line: 5, new_line: 6 },
          { meta_data: { old_pos: 10, new_pos: 11 } },
          { new_line: 10, old_line: 11 },
        ],
      };
      const dispatch = jest.fn();

      await diffActions.fetchLinkedExpandedLine(
        { getters: { linkedFile }, dispatch },
        { fileHash: linkedFile.file_hash, oldLine: 7, newLine: 8 },
      );
      expect(dispatch).toHaveBeenCalledWith('loadMoreLines', {
        endpoint: linkedFile.context_lines_path,
        fileHash: linkedFile.file_hash,
        isExpandDown: false,
        lineNumbers: {
          oldLineNumber: 10,
          newLineNumber: 11,
        },
        params: {
          bottom: false,
          offset: 1,
          since: 7,
          to: 10,
          unfold: false,
        },
      });
    });

    it('expands lines downwards in the middle of the file', async () => {
      const linkedFile = {
        file_hash: 'abc123',
        context_lines_path: `${TEST_HOST}/linked-file`,
        highlighted_diff_lines: [
          { old_line: 5, new_line: 6 },
          { meta_data: { old_pos: 50, new_pos: 51 } },
          { old_line: 50, new_line: 51 },
        ],
      };
      const dispatch = jest.fn();

      await diffActions.fetchLinkedExpandedLine(
        { getters: { linkedFile }, dispatch },
        { fileHash: linkedFile.file_hash, oldLine: 7, newLine: 8 },
      );
      expect(dispatch).toHaveBeenCalledWith('loadMoreLines', {
        endpoint: linkedFile.context_lines_path,
        fileHash: linkedFile.file_hash,
        isExpandDown: true,
        lineNumbers: {
          oldLineNumber: 5,
          newLineNumber: 6,
        },
        nextLineNumbers: {
          old_line: 50,
          new_line: 51,
        },
        params: {
          bottom: true,
          offset: 1,
          since: 7,
          to: 8,
          unfold: true,
        },
      });
    });

    it('expands lines at the very bottom', async () => {
      const linkedFile = {
        file_hash: 'abc123',
        context_lines_path: `${TEST_HOST}/linked-file`,
        highlighted_diff_lines: [
          { old_line: 5, new_line: 6 },
          { meta_data: { old_pos: 5, new_pos: 6 } },
        ],
      };
      const dispatch = jest.fn();

      await diffActions.fetchLinkedExpandedLine(
        { getters: { linkedFile }, dispatch },
        { fileHash: linkedFile.file_hash, oldLine: 20, newLine: 21 },
      );
      expect(dispatch).toHaveBeenCalledWith('loadMoreLines', {
        endpoint: linkedFile.context_lines_path,
        fileHash: linkedFile.file_hash,
        isExpandDown: false,
        lineNumbers: {
          oldLineNumber: 5,
          newLineNumber: 6,
        },
        params: {
          bottom: true,
          offset: 1,
          since: 7,
          to: 21,
          unfold: true,
        },
      });
    });
  });
});
