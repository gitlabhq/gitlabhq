import { sortTree } from '~/ide/stores/utils';

describe('IDE store utils', () => {
  describe('sortTree', () => {
    const treeEntries = [
      { id: 1, name: 'a', key: 'z', type: 'blob', tree: [] },
      { id: 2, name: 'z', key: 'a', type: 'blob', tree: [] },
      { id: 3, name: 't', key: 't', type: 'tree', tree: [] },
    ];

    it.each`
      description                                | treeIn                              | key          | sequenceOut
      ${'sorts by name when no key is provided'} | ${[treeEntries[1], treeEntries[0]]} | ${undefined} | ${[1, 2]}
      ${'sorts by the provided key'}             | ${[treeEntries[0], treeEntries[1]]} | ${'key'}     | ${[2, 1]}
      ${'sorts sub-trees above blobs'}           | ${treeEntries}                      | ${undefined} | ${[3, 1, 2]}
    `('$description', ({ treeIn, key, sequenceOut }) => {
      const sorted = sortTree(treeIn, key);
      const ids = sorted.map((entry) => entry.id);

      expect(ids).toEqual(sequenceOut);
    });
  });
});
