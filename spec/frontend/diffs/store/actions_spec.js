import MockAdapter from 'axios-mock-adapter';
import Cookies from 'js-cookie';
import mockDiffFile from 'jest/diffs/mock_data/diff_file';
import {
  DIFF_VIEW_COOKIE_NAME,
  INLINE_DIFF_VIEW_TYPE,
  PARALLEL_DIFF_VIEW_TYPE,
  DIFFS_PER_PAGE,
} from '~/diffs/constants';
import {
  setBaseConfig,
  fetchDiffFiles,
  fetchDiffFilesBatch,
  fetchDiffFilesMeta,
  fetchCoverageFiles,
  assignDiscussionsToDiff,
  removeDiscussionsFromDiff,
  startRenderDiffsQueue,
  setInlineDiffViewType,
  setParallelDiffViewType,
  showCommentForm,
  cancelCommentForm,
  loadMoreLines,
  scrollToLineIfNeededInline,
  scrollToLineIfNeededParallel,
  loadCollapsedDiff,
  expandAllFiles,
  toggleFileDiscussions,
  saveDiffDiscussion,
  setHighlightedRow,
  toggleTreeOpen,
  scrollToFile,
  toggleShowTreeList,
  renderFileForDiscussionId,
  setRenderTreeList,
  setShowWhitespace,
  setRenderIt,
  receiveFullDiffError,
  fetchFullDiff,
  toggleFullDiff,
  switchToFullDiffFromRenamedFile,
  setFileCollapsed,
  setExpandedDiffLines,
  setSuggestPopoverDismissed,
  changeCurrentCommit,
  moveToNeighboringCommit,
} from '~/diffs/store/actions';
import eventHub from '~/notes/event_hub';
import * as types from '~/diffs/store/mutation_types';
import axios from '~/lib/utils/axios_utils';
import testAction from '../../helpers/vuex_action_helper';
import * as utils from '~/diffs/store/utils';
import * as commonUtils from '~/lib/utils/common_utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { diffMetadata } from '../mock_data/diff_metadata';
import createFlash from '~/flash';

jest.mock('~/flash', () => jest.fn());

describe('DiffsStoreActions', () => {
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
    ['requestAnimationFrame', 'requestIdleCallback'].forEach(method => {
      global[method] = cb => {
        cb();
      };
    });
  });

  afterEach(() => {
    ['requestAnimationFrame', 'requestIdleCallback'].forEach(method => {
      global[method] = originalMethods[method];
    });
    createFlash.mockClear();
  });

  describe('setBaseConfig', () => {
    it('should set given endpoint and project path', done => {
      const endpoint = '/diffs/set/endpoint';
      const endpointMetadata = '/diffs/set/endpoint/metadata';
      const endpointBatch = '/diffs/set/endpoint/batch';
      const endpointCoverage = '/diffs/set/coverage_reports';
      const projectPath = '/root/project';
      const dismissEndpoint = '/-/user_callouts';
      const showSuggestPopover = false;
      const useSingleDiffStyle = false;

      testAction(
        setBaseConfig,
        {
          endpoint,
          endpointBatch,
          endpointMetadata,
          endpointCoverage,
          projectPath,
          dismissEndpoint,
          showSuggestPopover,
          useSingleDiffStyle,
        },
        {
          endpoint: '',
          endpointBatch: '',
          endpointMetadata: '',
          endpointCoverage: '',
          projectPath: '',
          dismissEndpoint: '',
          showSuggestPopover: true,
          useSingleDiffStyle: true,
        },
        [
          {
            type: types.SET_BASE_CONFIG,
            payload: {
              endpoint,
              endpointMetadata,
              endpointBatch,
              endpointCoverage,
              projectPath,
              dismissEndpoint,
              showSuggestPopover,
              useSingleDiffStyle,
            },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('fetchDiffFiles', () => {
    it('should fetch diff files', done => {
      const endpoint = '/fetch/diff/files?view=inline&w=1';
      const mock = new MockAdapter(axios);
      const res = { diff_files: 1, merge_request_diffs: [] };
      mock.onGet(endpoint).reply(200, res);

      testAction(
        fetchDiffFiles,
        {},
        { endpoint, diffFiles: [], showWhitespace: false, diffViewType: 'inline' },
        [
          { type: types.SET_LOADING, payload: true },
          { type: types.SET_LOADING, payload: false },
          { type: types.SET_MERGE_REQUEST_DIFFS, payload: res.merge_request_diffs },
          { type: types.SET_DIFF_DATA, payload: res },
        ],
        [],
        () => {
          mock.restore();
          done();
        },
      );

      fetchDiffFiles({ state: { endpoint }, commit: () => null })
        .then(data => {
          expect(data).toEqual(res);
          done();
        })
        .catch(done.fail);
    });
  });

  describe('fetchDiffFilesBatch', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    it('should fetch batch diff files', done => {
      const endpointBatch = '/fetch/diffs_batch';
      const res1 = { diff_files: [], pagination: { next_page: 2 } };
      const res2 = { diff_files: [], pagination: {} };
      mock
        .onGet(
          mergeUrlParams(
            {
              per_page: DIFFS_PER_PAGE,
              w: '1',
              view: 'inline',
              page: 1,
            },
            endpointBatch,
          ),
        )
        .reply(200, res1)
        .onGet(
          mergeUrlParams(
            {
              per_page: DIFFS_PER_PAGE,
              w: '1',
              view: 'inline',
              page: 2,
            },
            endpointBatch,
          ),
        )
        .reply(200, res2);

      testAction(
        fetchDiffFilesBatch,
        {},
        { endpointBatch, useSingleDiffStyle: true, diffViewType: 'inline' },
        [
          { type: types.SET_BATCH_LOADING, payload: true },
          { type: types.SET_RETRIEVING_BATCHES, payload: true },
          { type: types.SET_DIFF_DATA_BATCH, payload: { diff_files: res1.diff_files } },
          { type: types.SET_BATCH_LOADING, payload: false },
          { type: types.SET_DIFF_DATA_BATCH, payload: { diff_files: [] } },
          { type: types.SET_BATCH_LOADING, payload: false },
          { type: types.SET_RETRIEVING_BATCHES, payload: false },
        ],
        [],
        done,
      );
    });

    it.each`
      viewStyle     | otherView
      ${'inline'}   | ${'parallel'}
      ${'parallel'} | ${'inline'}
    `(
      'should make a request with the view parameter "$viewStyle" when the batchEndpoint already contains "$otherView"',
      ({ viewStyle, otherView }) => {
        const endpointBatch = '/fetch/diffs_batch';

        fetchDiffFilesBatch({
          commit: () => {},
          state: {
            endpointBatch: `${endpointBatch}?view=${otherView}`,
            useSingleDiffStyle: true,
            diffViewType: viewStyle,
          },
        })
          .then(() => {
            expect(mock.history.get[0].url).toContain(`view=${viewStyle}`);
            expect(mock.history.get[0].url).not.toContain(`view=${otherView}`);
          })
          .catch(() => {});
      },
    );
  });

  describe('fetchDiffFilesMeta', () => {
    const endpointMetadata = '/fetch/diffs_metadata.json?view=inline';
    const noFilesData = { ...diffMetadata };
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);

      delete noFilesData.diff_files;

      mock.onGet(endpointMetadata).reply(200, diffMetadata);
    });

    it('should fetch diff meta information', done => {
      testAction(
        fetchDiffFilesMeta,
        {},
        { endpointMetadata },
        [
          { type: types.SET_LOADING, payload: true },
          { type: types.SET_LOADING, payload: false },
          { type: types.SET_MERGE_REQUEST_DIFFS, payload: diffMetadata.merge_request_diffs },
          { type: types.SET_DIFF_DATA, payload: noFilesData },
        ],
        [],
        () => {
          mock.restore();
          done();
        },
      );
    });
  });

  describe('when the single diff view feature flag is off', () => {
    describe('fetchDiffFiles', () => {
      it('should fetch diff files', done => {
        const endpoint = '/fetch/diff/files?w=1';
        const mock = new MockAdapter(axios);
        const res = { diff_files: 1, merge_request_diffs: [] };
        mock.onGet(endpoint).reply(200, res);

        testAction(
          fetchDiffFiles,
          {},
          {
            endpoint,
            diffFiles: [],
            showWhitespace: false,
            diffViewType: 'inline',
            useSingleDiffStyle: false,
          },
          [
            { type: types.SET_LOADING, payload: true },
            { type: types.SET_LOADING, payload: false },
            { type: types.SET_MERGE_REQUEST_DIFFS, payload: res.merge_request_diffs },
            { type: types.SET_DIFF_DATA, payload: res },
          ],
          [],
          () => {
            mock.restore();
            done();
          },
        );

        fetchDiffFiles({ state: { endpoint }, commit: () => null })
          .then(data => {
            expect(data).toEqual(res);
            done();
          })
          .catch(done.fail);
      });
    });

    describe('fetchDiffFilesBatch', () => {
      let mock;

      beforeEach(() => {
        mock = new MockAdapter(axios);
      });

      afterEach(() => {
        mock.restore();
      });

      it('should fetch batch diff files', done => {
        const endpointBatch = '/fetch/diffs_batch';
        const res1 = { diff_files: [], pagination: { next_page: 2 } };
        const res2 = { diff_files: [], pagination: {} };
        mock
          .onGet(mergeUrlParams({ per_page: DIFFS_PER_PAGE, w: '1', page: 1 }, endpointBatch))
          .reply(200, res1)
          .onGet(mergeUrlParams({ per_page: DIFFS_PER_PAGE, w: '1', page: 2 }, endpointBatch))
          .reply(200, res2);

        testAction(
          fetchDiffFilesBatch,
          {},
          { endpointBatch, useSingleDiffStyle: false },
          [
            { type: types.SET_BATCH_LOADING, payload: true },
            { type: types.SET_RETRIEVING_BATCHES, payload: true },
            { type: types.SET_DIFF_DATA_BATCH, payload: { diff_files: res1.diff_files } },
            { type: types.SET_BATCH_LOADING, payload: false },
            { type: types.SET_DIFF_DATA_BATCH, payload: { diff_files: [] } },
            { type: types.SET_BATCH_LOADING, payload: false },
            { type: types.SET_RETRIEVING_BATCHES, payload: false },
          ],
          [],
          done,
        );
      });

      it.each`
        querystrings        | requestUrl
        ${'?view=parallel'} | ${'/fetch/diffs_batch?view=parallel'}
        ${'?view=inline'}   | ${'/fetch/diffs_batch?view=inline'}
        ${''}               | ${'/fetch/diffs_batch'}
      `(
        'should use the endpoint $requestUrl if the endpointBatch in state includes `$querystrings` as a querystring',
        ({ querystrings, requestUrl }) => {
          const endpointBatch = '/fetch/diffs_batch';

          fetchDiffFilesBatch({
            commit: () => {},
            state: {
              endpointBatch: `${endpointBatch}${querystrings}`,
              diffViewType: 'inline',
            },
          })
            .then(() => {
              expect(mock.history.get[0].url).toEqual(requestUrl);
            })
            .catch(() => {});
        },
      );
    });

    describe('fetchDiffFilesMeta', () => {
      const endpointMetadata = '/fetch/diffs_metadata.json';
      const noFilesData = { ...diffMetadata };
      let mock;

      beforeEach(() => {
        mock = new MockAdapter(axios);

        delete noFilesData.diff_files;

        mock.onGet(endpointMetadata).reply(200, diffMetadata);
      });
      it('should fetch diff meta information', done => {
        testAction(
          fetchDiffFilesMeta,
          {},
          { endpointMetadata, useSingleDiffStyle: false },
          [
            { type: types.SET_LOADING, payload: true },
            { type: types.SET_LOADING, payload: false },
            { type: types.SET_MERGE_REQUEST_DIFFS, payload: diffMetadata.merge_request_diffs },
            { type: types.SET_DIFF_DATA, payload: noFilesData },
          ],
          [],
          () => {
            mock.restore();
            done();
          },
        );
      });
    });
  });

  describe('fetchCoverageFiles', () => {
    let mock;
    const endpointCoverage = '/fetch';

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => mock.restore());

    it('should commit SET_COVERAGE_DATA with received response', done => {
      const data = { files: { 'app.js': { '1': 0, '2': 1 } } };

      mock.onGet(endpointCoverage).reply(200, { data });

      testAction(
        fetchCoverageFiles,
        {},
        { endpointCoverage },
        [{ type: types.SET_COVERAGE_DATA, payload: { data } }],
        [],
        done,
      );
    });

    it('should show flash on API error', done => {
      mock.onGet(endpointCoverage).reply(400);

      testAction(fetchCoverageFiles, {}, { endpointCoverage }, [], [], () => {
        expect(createFlash).toHaveBeenCalledTimes(1);
        expect(createFlash).toHaveBeenCalledWith(expect.stringMatching('Something went wrong'));
        done();
      });
    });
  });

  describe('setHighlightedRow', () => {
    it('should mark currently selected diff and set lineHash and fileHash of highlightedRow', () => {
      testAction(setHighlightedRow, 'ABC_123', {}, [
        { type: types.SET_HIGHLIGHTED_ROW, payload: 'ABC_123' },
        { type: types.UPDATE_CURRENT_DIFF_FILE_ID, payload: 'ABC' },
      ]);
    });
  });

  describe('assignDiscussionsToDiff', () => {
    it('should merge discussions into diffs', done => {
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

      testAction(
        assignDiscussionsToDiff,
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
        done,
      );
    });
  });

  describe('removeDiscussionsFromDiff', () => {
    it('should remove discussions from diffs', done => {
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
        file_hash: 'ABC',
        line_code: 'ABC_1_1',
      };

      testAction(
        removeDiscussionsFromDiff,
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
        done,
      );
    });
  });

  describe('startRenderDiffsQueue', () => {
    it('should set all files to RENDER_FILE', () => {
      const state = {
        diffFiles: [
          {
            id: 1,
            renderIt: false,
            viewer: {
              collapsed: false,
            },
          },
          {
            id: 2,
            renderIt: false,
            viewer: {
              collapsed: false,
            },
          },
        ],
      };

      const pseudoCommit = (commitType, file) => {
        expect(commitType).toBe(types.RENDER_FILE);
        Object.assign(file, {
          renderIt: true,
        });
      };

      startRenderDiffsQueue({ state, commit: pseudoCommit });

      expect(state.diffFiles[0].renderIt).toBe(true);
      expect(state.diffFiles[1].renderIt).toBe(true);
    });
  });

  describe('setInlineDiffViewType', () => {
    it('should set diff view type to inline and also set the cookie properly', done => {
      testAction(
        setInlineDiffViewType,
        null,
        {},
        [{ type: types.SET_DIFF_VIEW_TYPE, payload: INLINE_DIFF_VIEW_TYPE }],
        [],
        () => {
          setImmediate(() => {
            expect(Cookies.get('diff_view')).toEqual(INLINE_DIFF_VIEW_TYPE);
            done();
          });
        },
      );
    });
  });

  describe('setParallelDiffViewType', () => {
    it('should set diff view type to parallel and also set the cookie properly', done => {
      testAction(
        setParallelDiffViewType,
        null,
        {},
        [{ type: types.SET_DIFF_VIEW_TYPE, payload: PARALLEL_DIFF_VIEW_TYPE }],
        [],
        () => {
          setImmediate(() => {
            expect(Cookies.get(DIFF_VIEW_COOKIE_NAME)).toEqual(PARALLEL_DIFF_VIEW_TYPE);
            done();
          });
        },
      );
    });
  });

  describe('showCommentForm', () => {
    it('should call mutation to show comment form', done => {
      const payload = { lineCode: 'lineCode', fileHash: 'hash' };

      testAction(
        showCommentForm,
        payload,
        {},
        [{ type: types.TOGGLE_LINE_HAS_FORM, payload: { ...payload, hasForm: true } }],
        [],
        done,
      );
    });
  });

  describe('cancelCommentForm', () => {
    it('should call mutation to cancel comment form', done => {
      const payload = { lineCode: 'lineCode', fileHash: 'hash' };

      testAction(
        cancelCommentForm,
        payload,
        {},
        [{ type: types.TOGGLE_LINE_HAS_FORM, payload: { ...payload, hasForm: false } }],
        [],
        done,
      );
    });
  });

  describe('loadMoreLines', () => {
    it('should call mutation to show comment form', done => {
      const endpoint = '/diffs/load/more/lines';
      const params = { since: 6, to: 26 };
      const lineNumbers = { oldLineNumber: 3, newLineNumber: 5 };
      const fileHash = 'ff9200';
      const isExpandDown = false;
      const nextLineNumbers = {};
      const options = { endpoint, params, lineNumbers, fileHash, isExpandDown, nextLineNumbers };
      const mock = new MockAdapter(axios);
      const contextLines = { contextLines: [{ lineCode: 6 }] };
      mock.onGet(endpoint).reply(200, contextLines);

      testAction(
        loadMoreLines,
        options,
        {},
        [
          {
            type: types.ADD_CONTEXT_LINES,
            payload: { lineNumbers, contextLines, params, fileHash, isExpandDown, nextLineNumbers },
          },
        ],
        [],
        () => {
          mock.restore();
          done();
        },
      );
    });
  });

  describe('loadCollapsedDiff', () => {
    const state = { showWhitespace: true };
    it('should fetch data and call mutation with response and the give parameter', done => {
      const file = { hash: 123, load_collapsed_diff_url: '/load/collapsed/diff/url' };
      const data = { hash: 123, parallelDiffLines: [{ lineCode: 1 }] };
      const mock = new MockAdapter(axios);
      const commit = jest.fn();
      mock.onGet(file.loadCollapsedDiffUrl).reply(200, data);

      loadCollapsedDiff({ commit, getters: { commitId: null }, state }, file)
        .then(() => {
          expect(commit).toHaveBeenCalledWith(types.ADD_COLLAPSED_DIFFS, { file, data });

          mock.restore();
          done();
        })
        .catch(done.fail);
    });

    it('should fetch data without commit ID', () => {
      const file = { load_collapsed_diff_url: '/load/collapsed/diff/url' };
      const getters = {
        commitId: null,
      };

      jest.spyOn(axios, 'get').mockReturnValue(Promise.resolve({ data: {} }));

      loadCollapsedDiff({ commit() {}, getters, state }, file);

      expect(axios.get).toHaveBeenCalledWith(file.load_collapsed_diff_url, {
        params: { commit_id: null, w: '0' },
      });
    });

    it('should fetch data with commit ID', () => {
      const file = { load_collapsed_diff_url: '/load/collapsed/diff/url' };
      const getters = {
        commitId: '123',
      };

      jest.spyOn(axios, 'get').mockReturnValue(Promise.resolve({ data: {} }));

      loadCollapsedDiff({ commit() {}, getters, state }, file);

      expect(axios.get).toHaveBeenCalledWith(file.load_collapsed_diff_url, {
        params: { commit_id: '123', w: '0' },
      });
    });
  });

  describe('expandAllFiles', () => {
    it('should change the collapsed prop from the diffFiles', done => {
      testAction(
        expandAllFiles,
        null,
        {},
        [
          {
            type: types.EXPAND_ALL_FILES,
          },
        ],
        [],
        done,
      );
    });
  });

  describe('toggleFileDiscussions', () => {
    it('should dispatch collapseDiscussion when all discussions are expanded', () => {
      const getters = {
        getDiffFileDiscussions: jest.fn(() => [{ id: 1 }]),
        diffHasAllExpandedDiscussions: jest.fn(() => true),
        diffHasAllCollapsedDiscussions: jest.fn(() => false),
      };

      const dispatch = jest.fn();

      toggleFileDiscussions({ getters, dispatch });

      expect(dispatch).toHaveBeenCalledWith(
        'collapseDiscussion',
        { discussionId: 1 },
        { root: true },
      );
    });

    it('should dispatch expandDiscussion when all discussions are collapsed', () => {
      const getters = {
        getDiffFileDiscussions: jest.fn(() => [{ id: 1 }]),
        diffHasAllExpandedDiscussions: jest.fn(() => false),
        diffHasAllCollapsedDiscussions: jest.fn(() => true),
      };

      const dispatch = jest.fn();

      toggleFileDiscussions({ getters, dispatch });

      expect(dispatch).toHaveBeenCalledWith(
        'expandDiscussion',
        { discussionId: 1 },
        { root: true },
      );
    });

    it('should dispatch expandDiscussion when some discussions are collapsed and others are expanded for the collapsed discussion', () => {
      const getters = {
        getDiffFileDiscussions: jest.fn(() => [{ expanded: false, id: 1 }]),
        diffHasAllExpandedDiscussions: jest.fn(() => false),
        diffHasAllCollapsedDiscussions: jest.fn(() => false),
      };

      const dispatch = jest.fn();

      toggleFileDiscussions({ getters, dispatch });

      expect(dispatch).toHaveBeenCalledWith(
        'expandDiscussion',
        { discussionId: 1 },
        { root: true },
      );
    });
  });

  describe('scrollToLineIfNeededInline', () => {
    const lineMock = {
      line_code: 'ABC_123',
    };

    it('should not call handleLocationHash when there is not hash', () => {
      window.location.hash = '';

      scrollToLineIfNeededInline({}, lineMock);

      expect(commonUtils.handleLocationHash).not.toHaveBeenCalled();
    });

    it('should not call handleLocationHash when the hash does not match any line', () => {
      window.location.hash = 'XYZ_456';

      scrollToLineIfNeededInline({}, lineMock);

      expect(commonUtils.handleLocationHash).not.toHaveBeenCalled();
    });

    it('should call handleLocationHash only when the hash matches a line', () => {
      window.location.hash = 'ABC_123';

      scrollToLineIfNeededInline(
        {},
        {
          lineCode: 'ABC_456',
        },
      );
      scrollToLineIfNeededInline({}, lineMock);
      scrollToLineIfNeededInline(
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

      scrollToLineIfNeededParallel({}, lineMock);

      expect(commonUtils.handleLocationHash).not.toHaveBeenCalled();
    });

    it('should not call handleLocationHash when the hash does not match any line', () => {
      window.location.hash = 'XYZ_456';

      scrollToLineIfNeededParallel({}, lineMock);

      expect(commonUtils.handleLocationHash).not.toHaveBeenCalled();
    });

    it('should call handleLocationHash only when the hash matches a line', () => {
      window.location.hash = 'ABC_123';

      scrollToLineIfNeededParallel(
        {},
        {
          left: null,
          right: {
            lineCode: 'ABC_456',
          },
        },
      );
      scrollToLineIfNeededParallel({}, lineMock);
      scrollToLineIfNeededParallel(
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
    it('dispatches actions', done => {
      const commitId = 'something';
      const formData = {
        diffFile: { ...mockDiffFile },
        noteableData: {},
      };
      const note = {};
      const state = {
        commit: {
          id: commitId,
        },
      };
      const dispatch = jest.fn(name => {
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

      saveDiffDiscussion({ state, dispatch }, { note, formData })
        .then(() => {
          expect(dispatch).toHaveBeenCalledTimes(5);
          expect(dispatch).toHaveBeenNthCalledWith(1, 'saveNote', expect.any(Object), {
            root: true,
          });

          const postData = dispatch.mock.calls[0][1];
          expect(postData.data.note.commit_id).toBe(commitId);

          expect(dispatch).toHaveBeenNthCalledWith(2, 'updateDiscussion', 'test', { root: true });
          expect(dispatch).toHaveBeenNthCalledWith(3, 'assignDiscussionsToDiff', ['discussion']);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('toggleTreeOpen', () => {
    it('commits TOGGLE_FOLDER_OPEN', done => {
      testAction(
        toggleTreeOpen,
        'path',
        {},
        [{ type: types.TOGGLE_FOLDER_OPEN, payload: 'path' }],
        [],
        done,
      );
    });
  });

  describe('scrollToFile', () => {
    let commit;

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

      scrollToFile({ state, commit }, 'path');

      expect(document.location.hash).toBe('#test');
    });

    it('commits UPDATE_CURRENT_DIFF_FILE_ID', () => {
      const state = {
        treeEntries: {
          path: {
            fileHash: 'test',
          },
        },
      };

      scrollToFile({ state, commit }, 'path');

      expect(commit).toHaveBeenCalledWith(types.UPDATE_CURRENT_DIFF_FILE_ID, 'test');
    });
  });

  describe('toggleShowTreeList', () => {
    it('commits toggle', done => {
      testAction(toggleShowTreeList, null, {}, [{ type: types.TOGGLE_SHOW_TREE_LIST }], [], done);
    });

    it('updates localStorage', () => {
      jest.spyOn(localStorage, 'setItem').mockImplementation(() => {});

      toggleShowTreeList({ commit() {}, state: { showTreeList: true } });

      expect(localStorage.setItem).toHaveBeenCalledWith('mr_tree_show', true);
    });

    it('does not update localStorage', () => {
      jest.spyOn(localStorage, 'setItem').mockImplementation(() => {});

      toggleShowTreeList({ commit() {}, state: { showTreeList: true } }, false);

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
            collapsed,
          },
          renderIt,
        },
      ],
    });

    beforeEach(() => {
      commit = jest.fn();
      $emit = jest.spyOn(eventHub, '$emit');
    });

    it('renders and expands file for the given discussion id', () => {
      const localState = state({ collapsed: true, renderIt: false });

      renderFileForDiscussionId({ rootState, state: localState, commit }, '123');

      expect(commit).toHaveBeenCalledWith('RENDER_FILE', localState.diffFiles[0]);
      expect($emit).toHaveBeenCalledTimes(1);
      expect(commonUtils.scrollToElement).toHaveBeenCalledTimes(1);
    });

    it('jumps to discussion on already rendered and expanded file', () => {
      const localState = state({ collapsed: false, renderIt: true });

      renderFileForDiscussionId({ rootState, state: localState, commit }, '123');

      expect(commit).not.toHaveBeenCalled();
      expect($emit).toHaveBeenCalledTimes(1);
      expect(commonUtils.scrollToElement).not.toHaveBeenCalled();
    });
  });

  describe('setRenderTreeList', () => {
    it('commits SET_RENDER_TREE_LIST', done => {
      testAction(
        setRenderTreeList,
        true,
        {},
        [{ type: types.SET_RENDER_TREE_LIST, payload: true }],
        [],
        done,
      );
    });

    it('sets localStorage', () => {
      setRenderTreeList({ commit() {} }, true);

      expect(localStorage.setItem).toHaveBeenCalledWith('mr_diff_tree_list', true);
    });
  });

  describe('setShowWhitespace', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation();
    });

    it('commits SET_SHOW_WHITESPACE', done => {
      testAction(
        setShowWhitespace,
        { showWhitespace: true },
        {},
        [{ type: types.SET_SHOW_WHITESPACE, payload: true }],
        [],
        done,
      );
    });

    it('sets localStorage', () => {
      setShowWhitespace({ commit() {} }, { showWhitespace: true });

      expect(localStorage.setItem).toHaveBeenCalledWith('mr_show_whitespace', true);
    });

    it('calls history pushState', () => {
      setShowWhitespace({ commit() {} }, { showWhitespace: true, pushState: true });

      expect(window.history.pushState).toHaveBeenCalled();
    });

    it('calls history pushState with merged params', () => {
      window.history.pushState({}, '', '?test=1');

      setShowWhitespace({ commit() {} }, { showWhitespace: true, pushState: true });

      expect(
        window.history.pushState.mock.calls[window.history.pushState.mock.calls.length - 1][2],
      ).toMatch(/(.*)\?test=1&w=0/);

      window.history.pushState({}, '', '?');
    });

    it('emits eventHub event', () => {
      setShowWhitespace({ commit() {} }, { showWhitespace: true, pushState: true });

      expect(eventHub.$emit).toHaveBeenCalledWith('refetchDiffData');
    });
  });

  describe('setRenderIt', () => {
    it('commits RENDER_FILE', done => {
      testAction(setRenderIt, 'file', {}, [{ type: types.RENDER_FILE, payload: 'file' }], [], done);
    });
  });

  describe('receiveFullDiffError', () => {
    it('updates state with the file that did not load', done => {
      testAction(
        receiveFullDiffError,
        'file',
        {},
        [{ type: types.RECEIVE_FULL_DIFF_ERROR, payload: 'file' }],
        [],
        done,
      );
    });
  });

  describe('fetchFullDiff', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      beforeEach(() => {
        mock.onGet(`${gl.TEST_HOST}/context`).replyOnce(200, ['test']);
      });

      it('commits the success and dispatches an action to expand the new lines', done => {
        const file = {
          context_lines_path: `${gl.TEST_HOST}/context`,
          file_path: 'test',
          file_hash: 'test',
        };
        testAction(
          fetchFullDiff,
          file,
          null,
          [{ type: types.RECEIVE_FULL_DIFF_SUCCESS, payload: { filePath: 'test' } }],
          [{ type: 'setExpandedDiffLines', payload: { file, data: ['test'] } }],
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet(`${gl.TEST_HOST}/context`).replyOnce(500);
      });

      it('dispatches receiveFullDiffError', done => {
        testAction(
          fetchFullDiff,
          { context_lines_path: `${gl.TEST_HOST}/context`, file_path: 'test', file_hash: 'test' },
          null,
          [],
          [{ type: 'receiveFullDiffError', payload: 'test' }],
          done,
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

    it('dispatches fetchFullDiff when file is not expanded', done => {
      testAction(
        toggleFullDiff,
        'test',
        state,
        [{ type: types.REQUEST_FULL_DIFF, payload: 'test' }],
        [{ type: 'fetchFullDiff', payload: state.diffFiles[0] }],
        done,
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
    const updatedViewer = { name: updatedViewerName, collapsed: false };
    const testData = [{ rich_text: 'test' }, { rich_text: 'file2' }];
    let renamedFile;
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      jest.spyOn(utils, 'prepareLineForRenamedFile').mockImplementation(() => preparedLine);
    });

    afterEach(() => {
      renamedFile = null;
      mock.restore();
    });

    describe('success', () => {
      beforeEach(() => {
        renamedFile = { ...testFile, context_lines_path: SUCCESS_URL };
        mock.onGet(SUCCESS_URL).replyOnce(200, testData);
      });

      it.each`
        diffViewType
        ${INLINE_DIFF_VIEW_TYPE}
        ${PARALLEL_DIFF_VIEW_TYPE}
      `(
        'performs the correct mutations and starts a render queue for view type $diffViewType',
        ({ diffViewType }) => {
          return testAction(
            switchToFullDiffFromRenamedFile,
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
            [{ type: 'startRenderDiffsQueue' }],
          );
        },
      );
    });
  });

  describe('setFileCollapsed', () => {
    it('commits SET_FILE_COLLAPSED', done => {
      testAction(
        setFileCollapsed,
        { filePath: 'test', collapsed: true },
        null,
        [{ type: types.SET_FILE_COLLAPSED, payload: { filePath: 'test', collapsed: true } }],
        [],
        done,
      );
    });
  });

  describe('setExpandedDiffLines', () => {
    beforeEach(() => {
      utils.idleCallback.mockImplementation(cb => {
        cb({ timeRemaining: () => 50 });
      });
    });

    it('commits SET_CURRENT_VIEW_DIFF_FILE_LINES when lines less than MAX_RENDERING_DIFF_LINES', done => {
      utils.convertExpandLines.mockImplementation(() => ['test']);

      testAction(
        setExpandedDiffLines,
        { file: { file_path: 'path' }, data: [] },
        { diffViewType: 'inline' },
        [
          {
            type: 'SET_HIDDEN_VIEW_DIFF_FILE_LINES',
            payload: { filePath: 'path', lines: ['test'] },
          },
          {
            type: 'SET_CURRENT_VIEW_DIFF_FILE_LINES',
            payload: { filePath: 'path', lines: ['test'] },
          },
        ],
        [],
        done,
      );
    });

    it('commits ADD_CURRENT_VIEW_DIFF_FILE_LINES when lines more than MAX_RENDERING_DIFF_LINES', done => {
      const lines = new Array(501).fill().map((_, i) => `line-${i}`);
      utils.convertExpandLines.mockReturnValue(lines);

      testAction(
        setExpandedDiffLines,
        { file: { file_path: 'path' }, data: [] },
        { diffViewType: 'inline' },
        [
          {
            type: 'SET_HIDDEN_VIEW_DIFF_FILE_LINES',
            payload: { filePath: 'path', lines },
          },
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
        done,
      );
    });
  });

  describe('setSuggestPopoverDismissed', () => {
    it('commits SET_SHOW_SUGGEST_POPOVER', done => {
      const state = { dismissEndpoint: `${gl.TEST_HOST}/-/user_callouts` };
      const mock = new MockAdapter(axios);
      mock.onPost(state.dismissEndpoint).reply(200, {});

      jest.spyOn(axios, 'post');

      testAction(
        setSuggestPopoverDismissed,
        null,
        state,
        [{ type: types.SET_SHOW_SUGGEST_POPOVER }],
        [],
        () => {
          expect(axios.post).toHaveBeenCalledWith(state.dismissEndpoint, {
            feature_name: 'suggest_popover_dismissed',
          });

          mock.restore();
          done();
        },
      );
    });
  });

  describe('changeCurrentCommit', () => {
    it('commits the new commit information and re-requests the diff metadata for the commit', () => {
      return testAction(
        changeCurrentCommit,
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
          changeCurrentCommit,
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
          moveToNeighboringCommit,
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
          moveToNeighboringCommit,
          { direction },
          { commit: currentCommit, isLoading: diffsAreLoading },
          [],
          [],
        );
      },
    );
  });
});
