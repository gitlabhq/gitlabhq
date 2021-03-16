import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Cookies from 'js-cookie';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import { INTERACTIVE_RESOLVE_MODE, EDIT_RESOLVE_MODE } from '~/merge_conflicts/constants';
import * as actions from '~/merge_conflicts/store/actions';
import * as types from '~/merge_conflicts/store/mutation_types';
import { restoreFileLinesState, markLine, decorateFiles } from '~/merge_conflicts/utils';

jest.mock('~/flash.js');
jest.mock('~/merge_conflicts/utils');
jest.mock('js-cookie');

describe('merge conflicts actions', () => {
  let mock;

  const files = [
    {
      blobPath: 'a',
    },
    { blobPath: 'b' },
  ];

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetchConflictsData', () => {
    const conflictsPath = 'conflicts/path/mock';

    it('on success dispatches setConflictsData', (done) => {
      mock.onGet(conflictsPath).reply(200, {});
      testAction(
        actions.fetchConflictsData,
        conflictsPath,
        {},
        [
          { type: types.SET_LOADING_STATE, payload: true },
          { type: types.SET_LOADING_STATE, payload: false },
        ],
        [{ type: 'setConflictsData', payload: {} }],
        done,
      );
    });

    it('when data has type equal to error ', (done) => {
      mock.onGet(conflictsPath).reply(200, { type: 'error', message: 'error message' });
      testAction(
        actions.fetchConflictsData,
        conflictsPath,
        {},
        [
          { type: types.SET_LOADING_STATE, payload: true },
          { type: types.SET_FAILED_REQUEST, payload: 'error message' },
          { type: types.SET_LOADING_STATE, payload: false },
        ],
        [],
        done,
      );
    });

    it('when request fails ', (done) => {
      mock.onGet(conflictsPath).reply(400);
      testAction(
        actions.fetchConflictsData,
        conflictsPath,
        {},
        [
          { type: types.SET_LOADING_STATE, payload: true },
          { type: types.SET_FAILED_REQUEST },
          { type: types.SET_LOADING_STATE, payload: false },
        ],
        [],
        done,
      );
    });
  });

  describe('setConflictsData', () => {
    it('INTERACTIVE_RESOLVE_MODE updates the correct file ', (done) => {
      decorateFiles.mockReturnValue([{ bar: 'baz' }]);
      testAction(
        actions.setConflictsData,
        { files, foo: 'bar' },
        {},
        [
          {
            type: types.SET_CONFLICTS_DATA,
            payload: { foo: 'bar', files: [{ bar: 'baz' }] },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('submitResolvedConflicts', () => {
    useMockLocationHelper();
    const resolveConflictsPath = 'resolve/conflicts/path/mock';

    it('on success reloads the page', (done) => {
      mock.onPost(resolveConflictsPath).reply(200, { redirect_to: 'hrefPath' });
      testAction(
        actions.submitResolvedConflicts,
        resolveConflictsPath,
        {},
        [{ type: types.SET_SUBMIT_STATE, payload: true }],
        [],
        () => {
          expect(window.location.assign).toHaveBeenCalledWith('hrefPath');
          done();
        },
      );
    });

    it('on errors shows flash', (done) => {
      mock.onPost(resolveConflictsPath).reply(400);
      testAction(
        actions.submitResolvedConflicts,
        resolveConflictsPath,
        {},
        [
          { type: types.SET_SUBMIT_STATE, payload: true },
          { type: types.SET_SUBMIT_STATE, payload: false },
        ],
        [],
        () => {
          expect(createFlash).toHaveBeenCalledWith({
            message: 'Failed to save merge conflicts resolutions. Please try again!',
          });
          done();
        },
      );
    });
  });

  describe('setLoadingState', () => {
    it('commits the right mutation', () => {
      testAction(
        actions.setLoadingState,
        true,
        {},
        [
          {
            type: types.SET_LOADING_STATE,
            payload: true,
          },
        ],
        [],
      );
    });
  });

  describe('setErrorState', () => {
    it('commits the right mutation', () => {
      testAction(
        actions.setErrorState,
        true,
        {},
        [
          {
            type: types.SET_ERROR_STATE,
            payload: true,
          },
        ],
        [],
      );
    });
  });

  describe('setFailedRequest', () => {
    it('commits the right mutation', () => {
      testAction(
        actions.setFailedRequest,
        'errors in the request',
        {},
        [
          {
            type: types.SET_FAILED_REQUEST,
            payload: 'errors in the request',
          },
        ],
        [],
      );
    });
  });

  describe('setViewType', () => {
    it('commits the right mutation', (done) => {
      const payload = 'viewType';
      testAction(
        actions.setViewType,
        payload,
        {},
        [
          {
            type: types.SET_VIEW_TYPE,
            payload,
          },
        ],
        [],
        () => {
          expect(Cookies.set).toHaveBeenCalledWith('diff_view', payload);
          done();
        },
      );
    });
  });

  describe('setSubmitState', () => {
    it('commits the right mutation', () => {
      testAction(
        actions.setSubmitState,
        true,
        {},
        [
          {
            type: types.SET_SUBMIT_STATE,
            payload: true,
          },
        ],
        [],
      );
    });
  });

  describe('updateCommitMessage', () => {
    it('commits the right mutation', () => {
      testAction(
        actions.updateCommitMessage,
        'some message',
        {},
        [
          {
            type: types.UPDATE_CONFLICTS_DATA,
            payload: { commitMessage: 'some message' },
          },
        ],
        [],
      );
    });
  });

  describe('setFileResolveMode', () => {
    it('INTERACTIVE_RESOLVE_MODE updates the correct file ', (done) => {
      testAction(
        actions.setFileResolveMode,
        { file: files[0], mode: INTERACTIVE_RESOLVE_MODE },
        { conflictsData: { files }, getFileIndex: () => 0 },
        [
          {
            type: types.UPDATE_FILE,
            payload: {
              file: { ...files[0], showEditor: false, resolveMode: INTERACTIVE_RESOLVE_MODE },
              index: 0,
            },
          },
        ],
        [],
        done,
      );
    });

    it('EDIT_RESOLVE_MODE updates the correct file ', (done) => {
      restoreFileLinesState.mockReturnValue([]);
      const file = {
        ...files[0],
        showEditor: true,
        loadEditor: true,
        resolutionData: {},
        resolveMode: EDIT_RESOLVE_MODE,
      };
      testAction(
        actions.setFileResolveMode,
        { file: files[0], mode: EDIT_RESOLVE_MODE },
        { conflictsData: { files }, getFileIndex: () => 0 },
        [
          {
            type: types.UPDATE_FILE,
            payload: {
              file,
              index: 0,
            },
          },
        ],
        [],
        () => {
          expect(restoreFileLinesState).toHaveBeenCalledWith(file);
          done();
        },
      );
    });
  });

  describe('setPromptConfirmationState', () => {
    it('updates the correct file ', (done) => {
      testAction(
        actions.setPromptConfirmationState,
        { file: files[0], promptDiscardConfirmation: true },
        { conflictsData: { files }, getFileIndex: () => 0 },
        [
          {
            type: types.UPDATE_FILE,
            payload: {
              file: { ...files[0], promptDiscardConfirmation: true },
              index: 0,
            },
          },
        ],
        [],
        done,
      );
    });
  });

  describe('handleSelected', () => {
    const file = {
      ...files[0],
      inlineLines: [{ id: 1, hasConflict: true }, { id: 2 }],
      parallelLines: [
        [{ id: 1, hasConflict: true }, { id: 1 }],
        [{ id: 2 }, { id: 3 }],
      ],
    };

    it('updates the correct file ', (done) => {
      const marLikeMockReturn = { foo: 'bar' };
      markLine.mockReturnValue(marLikeMockReturn);

      testAction(
        actions.handleSelected,
        { file, line: { id: 1, section: 'baz' } },
        { conflictsData: { files }, getFileIndex: () => 0 },
        [
          {
            type: types.UPDATE_FILE,
            payload: {
              file: {
                ...file,
                resolutionData: { 1: 'baz' },
                inlineLines: [marLikeMockReturn, { id: 2 }],
                parallelLines: [
                  [marLikeMockReturn, marLikeMockReturn],
                  [{ id: 2 }, { id: 3 }],
                ],
              },
              index: 0,
            },
          },
        ],
        [],
        () => {
          expect(markLine).toHaveBeenCalledTimes(3);
          done();
        },
      );
    });
  });
});
