import { cloneDeep } from 'lodash';
import {
  SNIPPET_BLOB_ACTION_CREATE,
  SNIPPET_BLOB_ACTION_UPDATE,
  SNIPPET_BLOB_ACTION_MOVE,
  SNIPPET_BLOB_ACTION_DELETE,
} from '~/snippets/constants';
import { decorateBlob, createBlob, diffAll } from '~/snippets/utils/blob';

jest.mock('lodash/uniqueId', () => arg => `${arg}fakeUniqueId`);

const TEST_RAW_BLOB = {
  rawPath: '/test/blob/7/raw',
};
const CONTENT_1 = 'Lorem ipsum dolar\nSit amit\n\nGoodbye!\n';
const CONTENT_2 = 'Lorem ipsum dolar sit amit.\n\nGoodbye!\n';

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
    // This object contains entries that contain an expected "diff" and the `id`
    // or `origContent` that should be used to generate the expected diff.
    const testEntries = {
      created: {
        id: 'blob_1',
        diff: {
          action: SNIPPET_BLOB_ACTION_CREATE,
          filePath: '/new/file',
          previousPath: '/new/file',
          content: CONTENT_1,
        },
      },
      deleted: {
        id: 'blob_2',
        diff: {
          action: SNIPPET_BLOB_ACTION_DELETE,
          filePath: '/src/delete/me',
          previousPath: '/src/delete/me',
          content: CONTENT_1,
        },
      },
      updated: {
        id: 'blob_3',
        origContent: CONTENT_1,
        diff: {
          action: SNIPPET_BLOB_ACTION_UPDATE,
          filePath: '/lorem.md',
          previousPath: '/lorem.md',
          content: CONTENT_2,
        },
      },
      renamed: {
        id: 'blob_4',
        diff: {
          action: SNIPPET_BLOB_ACTION_MOVE,
          filePath: '/dolar.md',
          previousPath: '/ipsum.md',
          content: CONTENT_1,
        },
      },
      renamedAndUpdated: {
        id: 'blob_5',
        origContent: CONTENT_1,
        diff: {
          action: SNIPPET_BLOB_ACTION_MOVE,
          filePath: '/sit.md',
          previousPath: '/sit/amit.md',
          content: CONTENT_2,
        },
      },
    };
    const createBlobsFromTestEntries = (entries, isOrig = false) =>
      entries.reduce(
        (acc, { id, diff, origContent }) =>
          Object.assign(acc, {
            [id]: {
              id,
              content: isOrig && origContent ? origContent : diff.content,
              path: isOrig ? diff.previousPath : diff.filePath,
            },
          }),
        {},
      );

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
