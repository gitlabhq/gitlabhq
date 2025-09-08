import {
  normalizePath,
  dedupeByFlatPathAndId,
  generateShowMoreItem,
} from '~/repository/file_tree_browser/utils';

describe('File tree browser utilities', () => {
  describe('normalizePath', () => {
    it.each`
      input                    | expected
      ${'path/to/file'}        | ${'/path/to/file'}
      ${'/path/to/file'}       | ${'/path/to/file'}
      ${'/path/to/directory/'} | ${'/path/to/directory'}
      ${'/'}                   | ${'/'}
      ${'path/to/directory/'}  | ${'/path/to/directory'}
      ${''}                    | ${'/'}
    `('normalizes "$input" to "$expected"', ({ input, expected }) => {
      expect(normalizePath(input)).toBe(expected);
    });
  });

  describe('dedupeByFlatPathAndId', () => {
    const createItems = (...specs) =>
      specs.map(([flatPath, id, extras = {}]) => ({ flatPath, id, ...extras }));

    it('removes duplicates based on flatPath and id', () => {
      const items = createItems(
        ['path/file.js', '123'],
        ['path/file.js', '123'], // Duplicate
        ['path/other.js', '456'],
      );

      const result = dedupeByFlatPathAndId(items);
      expect(result).toHaveLength(2);
      expect(result.map((i) => i.flatPath)).toEqual(['path/file.js', 'path/other.js']);
    });

    it.each`
      scenario                             | input                                                              | expectedLength
      ${'same flatPath but different ids'} | ${createItems(['path/file.js', '123'], ['path/file.js', '456'])}   | ${2}
      ${'same id but different flatPaths'} | ${createItems(['path/file1.js', '123'], ['path/file2.js', '123'])} | ${2}
      ${'empty array'}                     | ${[]}                                                              | ${0}
    `('handles $scenario', ({ input, expectedLength }) => {
      expect(dedupeByFlatPathAndId(input)).toHaveLength(expectedLength);
    });

    it('preserves additional properties', () => {
      const items = createItems(['path/file.js', '123', { name: 'file.js', size: 1000 }]);
      const result = dedupeByFlatPathAndId(items);

      expect(result[0]).toMatchObject({
        flatPath: 'path/file.js',
        id: '123',
        name: 'file.js',
        size: 1000,
      });
    });
  });

  describe('generateShowMoreItem', () => {
    it('generates show more item with correct structure', () => {
      const result = generateShowMoreItem('file-123', '/path/to/directory', 2);

      expect(result).toEqual({
        id: 'file-123-show-more',
        level: 2,
        parentPath: '/path/to/directory',
        isShowMore: true,
      });
    });

    it.each`
      id            | parentPath   | level | expectedId
      ${''}         | ${'/'}       | ${0}  | ${'-show-more'}
      ${'abc'}      | ${'/root'}   | ${1}  | ${'abc-show-more'}
      ${'file-456'} | ${'/nested'} | ${3}  | ${'file-456-show-more'}
    `('creates id "$expectedId" from "$id"', ({ id, parentPath, level, expectedId }) => {
      const result = generateShowMoreItem(id, parentPath, level);
      expect(result.id).toBe(expectedId);
      expect(result.level).toBe(level);
      expect(result.parentPath).toBe(parentPath);
      expect(result.isShowMore).toBe(true);
    });
  });
});
