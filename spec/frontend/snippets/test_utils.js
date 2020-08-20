import {
  SNIPPET_BLOB_ACTION_CREATE,
  SNIPPET_BLOB_ACTION_UPDATE,
  SNIPPET_BLOB_ACTION_MOVE,
  SNIPPET_BLOB_ACTION_DELETE,
} from '~/snippets/constants';

const CONTENT_1 = 'Lorem ipsum dolar\nSit amit\n\nGoodbye!\n';
const CONTENT_2 = 'Lorem ipsum dolar sit amit.\n\nGoodbye!\n';

export const testEntries = {
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

export const createBlobFromTestEntry = ({ diff, origContent }, isOrig = false) => ({
  content: isOrig && origContent ? origContent : diff.content,
  path: isOrig ? diff.previousPath : diff.filePath,
});

export const createBlobsFromTestEntries = (entries, isOrig = false) =>
  entries.reduce(
    (acc, entry) =>
      Object.assign(acc, {
        [entry.id]: {
          id: entry.id,
          ...createBlobFromTestEntry(entry, isOrig),
        },
      }),
    {},
  );
