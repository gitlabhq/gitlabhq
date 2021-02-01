import { InMemoryCache } from 'apollo-cache-inmemory';
import {
  updateStoreAfterDesignsDelete,
  updateStoreAfterAddImageDiffNote,
  updateStoreAfterUploadDesign,
  updateStoreAfterRepositionImageDiffNote,
} from '~/design_management/utils/cache_update';
import {
  designDeletionError,
  ADD_IMAGE_DIFF_NOTE_ERROR,
  UPDATE_IMAGE_DIFF_NOTE_ERROR,
} from '~/design_management/utils/error_messages';
import createFlash from '~/flash';
import design from '../mock_data/design';

jest.mock('~/flash.js');

describe('Design Management cache update', () => {
  const mockErrors = ['code red!'];

  let mockStore;

  beforeEach(() => {
    mockStore = new InMemoryCache();
  });

  describe('error handling', () => {
    it.each`
      fnName                                   | subject                                    | errorMessage                               | extraArgs
      ${'updateStoreAfterDesignsDelete'}       | ${updateStoreAfterDesignsDelete}           | ${designDeletionError({ singular: true })} | ${[[design]]}
      ${'updateStoreAfterAddImageDiffNote'}    | ${updateStoreAfterAddImageDiffNote}        | ${ADD_IMAGE_DIFF_NOTE_ERROR}               | ${[]}
      ${'updateStoreAfterUploadDesign'}        | ${updateStoreAfterUploadDesign}            | ${mockErrors[0]}                           | ${[]}
      ${'updateStoreAfterUpdateImageDiffNote'} | ${updateStoreAfterRepositionImageDiffNote} | ${UPDATE_IMAGE_DIFF_NOTE_ERROR}            | ${[]}
    `('$fnName handles errors in response', ({ subject, extraArgs, errorMessage }) => {
      expect(createFlash).not.toHaveBeenCalled();
      expect(() => subject(mockStore, { errors: mockErrors }, {}, ...extraArgs)).toThrow();
      expect(createFlash).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalledWith({ message: errorMessage });
    });
  });
});
