import { cloneDeep } from 'lodash';
import { decorateBlob, createBlob, diffAll } from '~/snippets/utils/blob';
import { testEntries, createBlobsFromTestEntries } from '../test_utils';

jest.mock('lodash/uniqueId', () => (arg) => `${arg}fakeUniqueId`);

const TEST_RAW_BLOB = {
  rawPath: '/test/blob/7/raw',
};

describe('~/snippets/utils/blob', () => {
  describe('decorateBlob', () => {
    it('should decorate the given object with local blob properties', () => {
      const orig = cloneDeep(TEST_RAW_BLOB);

      expect(decorateBlob(orig)).toEqual({
        ...TEST_RAW_BLOB,
        id: 'blob_local_fakeUniqueId',
        isLoaded: false,
        content: '',
      });
    });
  });

  describe('createBlob', () => {
    it('should create an empty local blob', () => {
      expect(createBlob()).toEqual({
        id: 'blob_local_fakeUniqueId',
        isLoaded: true,
        content: '',
        path: '',
      });
    });
  });

  describe('diffAll', () => {
    it('should create diff from original files', () => {
      const origBlobs = createBlobsFromTestEntries(
        [
          testEntries.deleted,
          testEntries.updated,
          testEntries.renamed,
          testEntries.renamedAndUpdated,
        ],
        true,
      );
      const blobs = createBlobsFromTestEntries([
        testEntries.created,
        testEntries.updated,
        testEntries.renamed,
        testEntries.renamedAndUpdated,
      ]);

      expect(diffAll(blobs, origBlobs)).toEqual([
        testEntries.deleted.diff,
        testEntries.created.diff,
        testEntries.updated.diff,
        testEntries.renamed.diff,
        testEntries.renamedAndUpdated.diff,
      ]);
    });
  });
});
