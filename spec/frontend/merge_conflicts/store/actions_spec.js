import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Cookies from '~/lib/utils/cookies';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import { INTERACTIVE_RESOLVE_MODE, EDIT_RESOLVE_MODE } from '~/merge_conflicts/constants';
import * as actions from '~/merge_conflicts/store/actions';
import * as types from '~/merge_conflicts/store/mutation_types';
import { restoreFileLinesState, markLine, decorateFiles } from '~/merge_conflicts/utils';

jest.mock('~/alert');
jest.mock('~/merge_conflicts/utils');
jest.mock('~/lib/utils/cookies');

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

    it('on success dispatches setConflictsData', () => {
      mock.onGet(conflictsPath).reply(HTTP_STATUS_OK, {});
      return testAction(
        actions.fetchConflictsData,
        conflictsPath,
        {},
        [
          { type: types.SET_LOADING_STATE, payload: true },
          { type: types.SET_LOADING_STATE, payload: false },
        ],
        [{ type: 'setConflictsData', payload: {} }],
      );
    });

    it('when data has type equal to error', () => {
      mock.onGet(conflictsPath).reply(HTTP_STATUS_OK, { type: 'error', message: 'error message' });
      return testAction(
        actions.fetchConflictsData,
        conflictsPath,
        {},
        [
          { type: types.SET_LOADING_STATE, payload: true },
          { type: types.SET_FAILED_REQUEST, payload: 'error message' },
          { type: types.SET_LOADING_STATE, payload: false },
        ],
        [],
      );
    });

    it('when request fails', () => {
      mock.onGet(conflictsPath).reply(HTTP_STATUS_BAD_REQUEST);
      return testAction(
        actions.fetchConflictsData,
        conflictsPath,
        {},
        [
          { type: types.SET_LOADING_STATE, payload: true },
          { type: types.SET_FAILED_REQUEST },
          { type: types.SET_LOADING_STATE, payload: false },
        ],
        [],
      );
    });
  });

  describe('setConflictsData', () => {
    it('INTERACTIVE_RESOLVE_MODE updates the correct file', () => {
      decorateFiles.mockReturnValue([{ bar: 'baz' }]);
      return testAction(
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
      );
    });
  });

  describe('submitResolvedConflicts', () => {
    useMockLocationHelper();
    const resolveConflictsPath = 'resolve/conflicts/path/mock';

    it('on success reloads the page', async () => {
      mock.onPost(resolveConflictsPath).reply(HTTP_STATUS_OK, { redirect_to: 'hrefPath' });
      await testAction(
        actions.submitResolvedConflicts,
        resolveConflictsPath,
        {},
        [{ type: types.SET_SUBMIT_STATE, payload: true }],
        [],
      );
      expect(window.location.assign).toHaveBeenCalledWith('hrefPath');
    });

    it('on errors shows an alert', async () => {
      mock.onPost(resolveConflictsPath).reply(HTTP_STATUS_BAD_REQUEST);
      await testAction(
        actions.submitResolvedConflicts,
        resolveConflictsPath,
        {},
        [
          { type: types.SET_SUBMIT_STATE, payload: true },
          { type: types.SET_SUBMIT_STATE, payload: false },
        ],
        [],
      );
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to save merge conflicts resolutions. Please try again!',
      });
    });
  });

  describe('setLoadingState', () => {
    it('commits the right mutation', () => {
      return testAction(
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
      return testAction(
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
      return testAction(
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
    it('commits the right mutation', async () => {
      const payload = 'viewType';
      await testAction(
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
      );
      expect(Cookies.set).toHaveBeenCalledWith('diff_view', payload, {
        expires: 365,
        secure: false,
      });
    });
  });

  describe('setSubmitState', () => {
    it('commits the right mutation', () => {
      return testAction(
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
      return testAction(
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
    it('INTERACTIVE_RESOLVE_MODE updates the correct file', () => {
      return testAction(
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
      );
    });

    it('EDIT_RESOLVE_MODE updates the correct file', async () => {
      restoreFileLinesState.mockReturnValue([]);
      const file = {
        ...files[0],
        showEditor: true,
        loadEditor: true,
        resolutionData: {},
        resolveMode: EDIT_RESOLVE_MODE,
      };
      await testAction(
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
      );
      expect(restoreFileLinesState).toHaveBeenCalledWith(file);
    });
  });

  describe('setPromptConfirmationState', () => {
    it('updates the correct file', () => {
      return testAction(
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

    it('updates the correct file', async () => {
      const marLikeMockReturn = { foo: 'bar' };
      markLine.mockReturnValue(marLikeMockReturn);

      await testAction(
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
      );
      expect(markLine).toHaveBeenCalledTimes(3);
    });
  });
});
