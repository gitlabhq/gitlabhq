import { decorateFiles, splitParent } from '~/ide/lib/files';
import { decorateData } from '~/ide/stores/utils';

const TEST_BLOB_DATA = { mimeType: 'test/mime' };

const createEntries = (paths) => {
  const createEntry = (acc, { path, type, children }) => {
    const { name, parent } = splitParent(path);

    acc[path] = {
      ...decorateData({
        id: path,
        name,
        path,
        type,
        parentPath: parent,
      }),
      tree: children.map((childName) => expect.objectContaining({ name: childName })),
      ...(type === 'blob' ? TEST_BLOB_DATA : {}),
    };

    return acc;
  };

  const entries = paths.reduce(createEntry, {});

  // Wrap entries in expect.objectContaining.
  // We couldn't do this earlier because we still need to select properties from parent entries.
  return Object.keys(entries).reduce((acc, key) => {
    acc[key] = expect.objectContaining(entries[key]);

    return acc;
  }, {});
};

describe('IDE lib decorate files', () => {
  it('creates entries and treeList', () => {
    const data = ['app/assets/apples/foo.js', 'app/bugs.js', 'app/#weird#file?.txt', 'README.md'];
    const expectedEntries = createEntries([
      { path: 'app', type: 'tree', children: ['assets', '#weird#file?.txt', 'bugs.js'] },
      { path: 'app/assets', type: 'tree', children: ['apples'] },
      { path: 'app/assets/apples', type: 'tree', children: ['foo.js'] },
      { path: 'app/assets/apples/foo.js', type: 'blob', children: [] },
      { path: 'app/bugs.js', type: 'blob', children: [] },
      { path: 'app/#weird#file?.txt', type: 'blob', children: [] },
      { path: 'README.md', type: 'blob', children: [] },
    ]);

    const { entries, treeList } = decorateFiles({ data, blobData: TEST_BLOB_DATA });

    // Here we test the keys and then each key/value individually because `expect(entries).toEqual(expectedEntries)`
    // was taking a very long time for some reason. Probably due to large objects and nested `expect.objectContaining`.
    const entryKeys = Object.keys(entries);

    expect(entryKeys).toEqual(Object.keys(expectedEntries));
    entryKeys.forEach((key) => {
      expect(entries[key]).toEqual(expectedEntries[key]);
    });

    expect(treeList).toEqual([expectedEntries.app, expectedEntries['README.md']]);
  });
});
