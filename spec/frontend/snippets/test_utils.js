import { TEST_HOST } from 'helpers/test_constants';
import {
  SNIPPET_BLOB_ACTION_CREATE,
  SNIPPET_BLOB_ACTION_UPDATE,
  SNIPPET_BLOB_ACTION_MOVE,
  SNIPPET_BLOB_ACTION_DELETE,
} from '~/snippets/constants';

const CONTENT_1 = 'Lorem ipsum dolar\nSit amit\n\nGoodbye!\n';
const CONTENT_2 = 'Lorem ipsum dolar sit amit.\n\nGoodbye!\n';

export const createGQLSnippet = () => ({
  __typename: 'Snippet',
  id: 7,
  title: 'Snippet Title',
  description: 'Lorem ipsum snippet desc',
  descriptionHtml: '<p>Lorem ipsum snippet desc</p>',
  createdAt: new Date(Date.now() - 1e6),
  updatedAt: new Date(Date.now() - 1e3),
  httpUrlToRepo: `${TEST_HOST}/repo`,
  sshUrlToRepo: 'ssh://ssh.test/repo',
  blobs: [],
  userPermissions: {
    __typename: 'SnippetPermissions',
    adminSnippet: true,
    updateSnippet: true,
  },
  project: {
    __typename: 'Project',
    id: 'project-1',
    fullPath: 'group/project',
    webUrl: `${TEST_HOST}/group/project`,
    visibility: 'public',
  },
  author: {
    __typename: 'User',
    id: 1,
    avatarUrl: `${TEST_HOST}/avatar.png`,
    name: 'root',
    username: 'root',
    webUrl: `${TEST_HOST}/root`,
    status: {
      __typename: 'UserStatus',
      emoji: '',
      message: '',
    },
  },
  hidden: false,
  imported: false,
});

export const createGQLSnippetsQueryResponse = (snippets) => ({
  data: {
    snippets: {
      __typename: 'SnippetConnection',
      nodes: snippets,
    },
  },
});

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
  empty: {
    id: 'empty',
    diff: {
      action: SNIPPET_BLOB_ACTION_CREATE,
      filePath: '',
      previousPath: '',
      content: '',
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
