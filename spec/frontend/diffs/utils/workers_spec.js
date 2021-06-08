import { generateTreeList, getLowestSingleFolder, flattenTree } from '~/diffs/utils/workers';

describe('~/diffs/utils/workers', () => {
  describe('generateTreeList', () => {
    let files;

    beforeAll(() => {
      files = [
        {
          new_path: 'app/index.js',
          deleted_file: false,
          new_file: false,
          removed_lines: 10,
          added_lines: 0,
          file_hash: 'test',
        },
        {
          new_path: 'app/test/index.js',
          deleted_file: false,
          new_file: true,
          removed_lines: 0,
          added_lines: 0,
          file_hash: 'test',
        },
        {
          new_path: 'app/test/filepathneedstruncating.js',
          deleted_file: false,
          new_file: true,
          removed_lines: 0,
          added_lines: 0,
          file_hash: 'test',
        },
        {
          new_path: 'package.json',
          deleted_file: true,
          new_file: false,
          removed_lines: 0,
          added_lines: 0,
          file_hash: 'test',
        },
      ];
    });

    it('creates a tree of files', () => {
      const { tree } = generateTreeList(files);

      expect(tree).toEqual([
        {
          key: 'app',
          path: 'app',
          name: 'app',
          type: 'tree',
          tree: [
            {
              addedLines: 0,
              changed: true,
              deleted: false,
              fileHash: 'test',
              key: 'app/index.js',
              name: 'index.js',
              parentPath: 'app/',
              path: 'app/index.js',
              removedLines: 10,
              tempFile: false,
              type: 'blob',
              tree: [],
            },
            {
              key: 'app/test',
              path: 'app/test',
              name: 'test',
              type: 'tree',
              opened: true,
              tree: [
                {
                  addedLines: 0,
                  changed: true,
                  deleted: false,
                  fileHash: 'test',
                  key: 'app/test/index.js',
                  name: 'index.js',
                  parentPath: 'app/test/',
                  path: 'app/test/index.js',
                  removedLines: 0,
                  tempFile: true,
                  type: 'blob',
                  tree: [],
                },
                {
                  addedLines: 0,
                  changed: true,
                  deleted: false,
                  fileHash: 'test',
                  key: 'app/test/filepathneedstruncating.js',
                  name: 'filepathneedstruncating.js',
                  parentPath: 'app/test/',
                  path: 'app/test/filepathneedstruncating.js',
                  removedLines: 0,
                  tempFile: true,
                  type: 'blob',
                  tree: [],
                },
              ],
            },
          ],
          opened: true,
        },
        {
          key: 'package.json',
          parentPath: '/',
          path: 'package.json',
          name: 'package.json',
          type: 'blob',
          changed: true,
          tempFile: false,
          deleted: true,
          fileHash: 'test',
          addedLines: 0,
          removedLines: 0,
          tree: [],
        },
      ]);
    });

    it('creates flat list of blobs & folders', () => {
      const { treeEntries } = generateTreeList(files);

      expect(Object.keys(treeEntries)).toEqual([
        'app',
        'app/index.js',
        'app/test',
        'app/test/index.js',
        'app/test/filepathneedstruncating.js',
        'package.json',
      ]);
    });
  });

  describe('getLowestSingleFolder', () => {
    it('returns path and tree of lowest single folder tree', () => {
      const folder = {
        name: 'app',
        type: 'tree',
        tree: [
          {
            name: 'javascripts',
            type: 'tree',
            tree: [
              {
                type: 'blob',
                name: 'index.js',
              },
            ],
          },
        ],
      };
      const { path, treeAcc } = getLowestSingleFolder(folder);

      expect(path).toEqual('app/javascripts');
      expect(treeAcc).toEqual([
        {
          type: 'blob',
          name: 'index.js',
        },
      ]);
    });

    it('returns passed in folders path & tree when more than tree exists', () => {
      const folder = {
        name: 'app',
        type: 'tree',
        tree: [
          {
            name: 'spec',
            type: 'blob',
            tree: [],
          },
        ],
      };
      const { path, treeAcc } = getLowestSingleFolder(folder);

      expect(path).toEqual('app');
      expect(treeAcc).toBeNull();
    });
  });

  describe('flattenTree', () => {
    it('returns flattened directory structure', () => {
      const tree = [
        {
          type: 'tree',
          name: 'app',
          tree: [
            {
              type: 'tree',
              name: 'javascripts',
              tree: [
                {
                  type: 'blob',
                  name: 'index.js',
                  tree: [],
                },
              ],
            },
          ],
        },
        {
          type: 'tree',
          name: 'ee',
          tree: [
            {
              type: 'tree',
              name: 'lib',
              tree: [
                {
                  type: 'tree',
                  name: 'ee',
                  tree: [
                    {
                      type: 'tree',
                      name: 'gitlab',
                      tree: [
                        {
                          type: 'tree',
                          name: 'checks',
                          tree: [
                            {
                              type: 'tree',
                              name: 'longtreenametomakepath',
                              tree: [
                                {
                                  type: 'blob',
                                  name: 'diff_check.rb',
                                  tree: [],
                                },
                              ],
                            },
                          ],
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          ],
        },
        {
          type: 'tree',
          name: 'spec',
          tree: [
            {
              type: 'tree',
              name: 'javascripts',
              tree: [],
            },
            {
              type: 'blob',
              name: 'index_spec.js',
              tree: [],
            },
          ],
        },
      ];
      const flattened = flattenTree(tree);

      expect(flattened).toEqual([
        {
          type: 'tree',
          name: 'app/javascripts',
          tree: [
            {
              type: 'blob',
              name: 'index.js',
              tree: [],
            },
          ],
        },
        {
          type: 'tree',
          name: 'ee/lib/…/…/…/longtreenametomakepath',
          tree: [
            {
              name: 'diff_check.rb',
              tree: [],
              type: 'blob',
            },
          ],
        },
        {
          type: 'tree',
          name: 'spec',
          tree: [
            {
              type: 'tree',
              name: 'javascripts',
              tree: [],
            },
            {
              type: 'blob',
              name: 'index_spec.js',
              tree: [],
            },
          ],
        },
      ]);
    });
  });
});
