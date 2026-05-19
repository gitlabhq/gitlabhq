import MockAdapter from 'axios-mock-adapter';
import { createTestingPinia } from '@pinia/testing';
import axios from '~/lib/utils/axios_utils';
import Cookies from '~/lib/utils/cookies';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { createAlert } from '~/alert';
import {
  CONFLICT_TYPES,
  EDIT_RESOLVE_MODE,
  INTERACTIVE_RESOLVE_MODE,
  VIEW_TYPES,
} from '~/merge_conflicts/constants';
import { useMergeConflicts } from '~/merge_conflicts/store';
import { decorateFiles, markLine, restoreFileLinesState } from '~/merge_conflicts/utils';

jest.mock('~/alert');
jest.mock('~/merge_conflicts/utils');
jest.mock('~/lib/utils/cookies');

describe('~/merge_conflicts/store', () => {
  let store;
  let axiosMock;

  beforeAll(() => {
    axiosMock = new MockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.reset();
  });

  afterAll(() => {
    axiosMock.restore();
  });

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useMergeConflicts();
  });

  const files = [{ blobPath: 'a' }, { blobPath: 'b' }];

  describe('fetchConflictsData', () => {
    const conflictsPath = 'conflicts/path/mock';

    it('sets isLoading=true while the request is in flight', () => {
      jest.spyOn(axios, 'get').mockReturnValueOnce(new Promise(() => {}));
      store.isLoading = false;

      store.fetchConflictsData(conflictsPath);

      expect(store.isLoading).toBe(true);
    });

    it('on success dispatches setConflictsData', async () => {
      axiosMock.onGet(conflictsPath).reply(HTTP_STATUS_OK, {});
      decorateFiles.mockReturnValue([]);

      await store.fetchConflictsData(conflictsPath);

      expect(decorateFiles).toHaveBeenCalledWith({});
      expect(store.isLoading).toBe(false);
    });

    it('when data has type equal to error', async () => {
      axiosMock
        .onGet(conflictsPath)
        .reply(HTTP_STATUS_OK, { type: 'error', message: 'error message' });

      await store.fetchConflictsData(conflictsPath);

      expect(store.hasError).toBe(true);
      expect(store.conflictsData.errorMessage).toBe('error message');
      expect(store.isLoading).toBe(false);
    });

    it('when request fails', async () => {
      axiosMock.onGet(conflictsPath).reply(HTTP_STATUS_BAD_REQUEST);

      await store.fetchConflictsData(conflictsPath);

      expect(store.hasError).toBe(true);
      expect(store.isLoading).toBe(false);
    });
  });

  describe('setConflictsData', () => {
    it('sets conflictsData from decorated files and normalized fields', () => {
      decorateFiles.mockReturnValue([{ bar: 'baz' }]);

      store.setConflictsData({
        files,
        commit_message: 'foo',
        source_branch: 'bar',
        target_branch: 'baz',
        commit_sha: '123456789',
      });

      expect(decorateFiles).toHaveBeenCalledWith({
        files,
        commit_message: 'foo',
        source_branch: 'bar',
        target_branch: 'baz',
        commit_sha: '123456789',
      });
      expect(store.conflictsData).toStrictEqual({
        files: [{ bar: 'baz' }],
        commitMessage: 'foo',
        sourceBranch: 'bar',
        targetBranch: 'baz',
        shortCommitSha: '1234567',
      });
    });
  });

  describe('submitResolvedConflicts', () => {
    useMockLocationHelper();
    const resolveConflictsPath = 'resolve/conflicts/path/mock';

    it('sets isSubmitting=true while the request is in flight', () => {
      jest.spyOn(axios, 'post').mockReturnValueOnce(new Promise(() => {}));

      store.submitResolvedConflicts(resolveConflictsPath);

      expect(store.isSubmitting).toBe(true);
    });

    it('on success reloads the page', async () => {
      axiosMock.onPost(resolveConflictsPath).reply(HTTP_STATUS_OK, { redirect_to: 'hrefPath' });

      await store.submitResolvedConflicts(resolveConflictsPath);

      expect(window.location.assign).toHaveBeenCalledWith('hrefPath');
    });

    it('on error shows an alert and resets isSubmitting', async () => {
      axiosMock.onPost(resolveConflictsPath).reply(HTTP_STATUS_BAD_REQUEST);

      await store.submitResolvedConflicts(resolveConflictsPath);

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Failed to save merge conflict resolutions. Please try again.',
      });
      expect(store.isSubmitting).toBe(false);
    });
  });

  describe('setLoadingState', () => {
    it('sets isLoading', () => {
      store.setLoadingState(true);

      expect(store.isLoading).toBe(true);
    });
  });

  describe('setErrorState', () => {
    it('sets hasError', () => {
      store.setErrorState(true);

      expect(store.hasError).toBe(true);
    });
  });

  describe('setFailedRequest', () => {
    it('sets hasError and errorMessage', () => {
      store.setFailedRequest('errors in the request');

      expect(store.hasError).toBe(true);
      expect(store.conflictsData.errorMessage).toBe('errors in the request');
    });
  });

  describe('setViewType', () => {
    it('sets diffView and isParallel=true and persists the cookie for PARALLEL', () => {
      store.setViewType(VIEW_TYPES.PARALLEL);

      expect(store.diffView).toBe(VIEW_TYPES.PARALLEL);
      expect(store.isParallel).toBe(true);
      expect(Cookies.set).toHaveBeenCalledWith('diff_view', VIEW_TYPES.PARALLEL, {
        expires: 365,
        secure: false,
      });
    });

    it('sets diffView and isParallel=false for INLINE', () => {
      store.setViewType(VIEW_TYPES.INLINE);

      expect(store.diffView).toBe(VIEW_TYPES.INLINE);
      expect(store.isParallel).toBe(false);
    });
  });

  describe('setSubmitState', () => {
    it('sets isSubmitting', () => {
      store.setSubmitState(true);

      expect(store.isSubmitting).toBe(true);
    });
  });

  describe('updateCommitMessage', () => {
    it('updates conflictsData.commitMessage', () => {
      store.updateCommitMessage('some message');

      expect(store.conflictsData.commitMessage).toBe('some message');
    });
  });

  describe('setFileResolveMode', () => {
    it('INTERACTIVE_RESOLVE_MODE updates the correct file', () => {
      store.conflictsData = { files: [{ ...files[0] }, { ...files[1] }] };

      store.setFileResolveMode({ file: files[0], mode: INTERACTIVE_RESOLVE_MODE });

      expect(store.conflictsData.files[0]).toEqual({
        ...files[0],
        showEditor: false,
        resolveMode: INTERACTIVE_RESOLVE_MODE,
      });
    });

    it('EDIT_RESOLVE_MODE updates the correct file', () => {
      restoreFileLinesState.mockReturnValue({ inlineLines: [], parallelLines: [] });
      store.conflictsData = { files: [{ ...files[0] }, { ...files[1] }] };

      store.setFileResolveMode({ file: files[0], mode: EDIT_RESOLVE_MODE });

      const expectedFile = {
        ...files[0],
        showEditor: true,
        loadEditor: true,
        resolutionData: {},
        parallelLines: [],
        inlineLines: [],
        resolveMode: EDIT_RESOLVE_MODE,
      };
      expect(store.conflictsData.files[0]).toEqual(expectedFile);
      expect(restoreFileLinesState).toHaveBeenCalledWith(expectedFile);
    });
  });

  describe('setPromptConfirmationState', () => {
    it('updates the correct file', () => {
      store.conflictsData = { files: [{ ...files[0] }, { ...files[1] }] };

      store.setPromptConfirmationState({ file: files[0], promptDiscardConfirmation: true });

      expect(store.conflictsData.files[0]).toEqual({
        ...files[0],
        promptDiscardConfirmation: true,
      });
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

    it('updates the correct file', () => {
      const markLikeMockReturn = { foo: 'bar' };
      markLine.mockReturnValue(markLikeMockReturn);
      store.conflictsData = { files: [{ ...files[0] }, { ...files[1] }] };

      store.handleSelected({ file, line: { id: 1, section: 'baz' } });

      expect(store.conflictsData.files[0]).toEqual({
        ...file,
        resolutionData: { 1: 'baz' },
        inlineLines: [markLikeMockReturn, { id: 2 }],
        parallelLines: [
          [markLikeMockReturn, markLikeMockReturn],
          [{ id: 2 }, { id: 3 }],
        ],
      });
      expect(markLine).toHaveBeenCalledTimes(3);
    });
  });

  describe('getConflictsCount', () => {
    it('returns zero when there are no files', () => {
      store.conflictsData.files = [];

      expect(store.getConflictsCount).toBe(0);
    });

    it(`counts the number of sections in files of type ${CONFLICT_TYPES.TEXT}`, () => {
      store.conflictsData.files = [
        { sections: [{ conflict: true }], type: CONFLICT_TYPES.TEXT },
        { sections: [{ conflict: true }, { conflict: true }], type: CONFLICT_TYPES.TEXT },
      ];

      expect(store.getConflictsCount).toBe(3);
    });

    it(`counts the number of files not of type ${CONFLICT_TYPES.TEXT}`, () => {
      store.conflictsData.files = [
        { sections: [{ conflict: true }], type: '' },
        { sections: [{ conflict: true }, { conflict: true }], type: '' },
      ];

      expect(store.getConflictsCount).toBe(2);
    });
  });

  describe('getConflictsCountText', () => {
    it('returns singular text for one conflict', () => {
      store.conflictsData.files = [{ sections: [{ conflict: true }], type: CONFLICT_TYPES.TEXT }];

      expect(store.getConflictsCountText).toBe('1 conflict');
    });

    it('returns plural text for multiple conflicts', () => {
      store.conflictsData.files = [
        {
          sections: [{ conflict: true }, { conflict: true }, { conflict: true }],
          type: CONFLICT_TYPES.TEXT,
        },
      ];

      expect(store.getConflictsCountText).toBe('3 conflicts');
    });
  });

  describe('isReadyToCommit', () => {
    it('returns false when isSubmitting is true', () => {
      store.conflictsData = { files: [], commitMessage: 'foo' };
      store.isSubmitting = true;

      expect(store.isReadyToCommit).toBe(false);
    });

    it('returns false when there is no commit message', () => {
      store.conflictsData = { files: [], commitMessage: '' };
      store.isSubmitting = false;

      expect(store.isReadyToCommit).toBe(false);
    });

    it('returns true when all conflicts are resolved, is not submitting, and has a commit message', () => {
      store.conflictsData = {
        commitMessage: 'foo',
        files: [
          {
            resolveMode: INTERACTIVE_RESOLVE_MODE,
            type: CONFLICT_TYPES.TEXT,
            sections: [{ conflict: true }],
            resolutionData: { foo: 'bar' },
          },
        ],
      };
      store.isSubmitting = false;

      expect(store.isReadyToCommit).toBe(true);
    });

    describe('unresolved', () => {
      it(`files with resolvedMode=${EDIT_RESOLVE_MODE} and empty content count as unresolved`, () => {
        store.conflictsData = {
          commitMessage: 'foo',
          files: [{ content: '', resolveMode: EDIT_RESOLVE_MODE }, { content: 'foo' }],
        };
        store.isSubmitting = false;

        expect(store.isReadyToCommit).toBe(false);
      });

      it(`counts resolvedConflicts vs unresolved ones in files with resolvedMode=${INTERACTIVE_RESOLVE_MODE}`, () => {
        store.conflictsData = {
          commitMessage: 'foo',
          files: [
            {
              resolveMode: INTERACTIVE_RESOLVE_MODE,
              type: CONFLICT_TYPES.TEXT,
              sections: [{ conflict: true }],
              resolutionData: {},
            },
          ],
        };
        store.isSubmitting = false;

        expect(store.isReadyToCommit).toBe(false);
      });
    });
  });

  describe('getCommitButtonText', () => {
    it('returns the in-progress text when submitting', () => {
      store.isSubmitting = true;

      expect(store.getCommitButtonText).toBe('Committing…');
    });

    it('returns the initial text when not submitting', () => {
      expect(store.getCommitButtonText).toBe('Commit to source branch');
    });
  });

  describe('getCommitData', () => {
    it('returns the commit payload', () => {
      const baseFile = { new_path: 'new_path', old_path: 'new_path' };
      store.conflictsData = {
        commitMessage: 'foo',
        files: [
          {
            ...baseFile,
            resolveMode: INTERACTIVE_RESOLVE_MODE,
            type: CONFLICT_TYPES.TEXT,
            sections: [{ conflict: true }],
            resolutionData: { bar: 'baz' },
          },
          {
            ...baseFile,
            resolveMode: EDIT_RESOLVE_MODE,
            type: CONFLICT_TYPES.TEXT,
            content: 'resolve_mode_content',
          },
          {
            ...baseFile,
            type: CONFLICT_TYPES.TEXT_EDITOR,
            content: 'text_editor_content',
          },
        ],
      };

      expect(store.getCommitData).toStrictEqual({
        commit_message: 'foo',
        files: [
          { ...baseFile, sections: { bar: 'baz' } },
          { ...baseFile, content: 'resolve_mode_content' },
          { ...baseFile, content: 'text_editor_content' },
        ],
      });
    });
  });

  describe('fileTextTypePresent', () => {
    it(`returns true if there is a file with type ${CONFLICT_TYPES.TEXT}`, () => {
      store.conflictsData.files = [{ type: CONFLICT_TYPES.TEXT }];

      expect(store.fileTextTypePresent).toBe(true);
    });

    it(`returns false if there is no file with type ${CONFLICT_TYPES.TEXT}`, () => {
      store.conflictsData.files = [{ type: CONFLICT_TYPES.TEXT_EDITOR }];

      expect(store.fileTextTypePresent).toBe(false);
    });
  });

  describe('getFileIndex', () => {
    it('returns the index of a file from its blob path', () => {
      const blobPath = 'blobPath/foo';
      store.conflictsData.files = [{ foo: 'bar' }, { baz: 'foo', blobPath }];

      expect(store.getFileIndex({ blobPath })).toBe(1);
    });
  });
});
