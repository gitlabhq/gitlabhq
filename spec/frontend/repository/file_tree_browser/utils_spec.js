import {
  normalizePath,
  dedupeByFlatPathAndId,
  generateShowMoreItem,
  directoryContainsChild,
  shouldStopPagination,
  hasMorePages,
  isExpandable,
  handleTreeKeydown,
} from '~/repository/file_tree_browser/utils';
import { FTB_MAX_PAGES, FTB_MAX_DEPTH } from '~/repository/constants';

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

  describe('directoryContainsChild', () => {
    const trees = [
      { name: 'src', id: '1' },
      { name: 'docs', id: '2' },
      { name: 'README.md', id: '3' },
    ];

    it.each`
      tree     | childName      | expected
      ${trees} | ${'docs'}      | ${true}
      ${trees} | ${'lib'}       | ${false}
      ${[]}    | ${'any'}       | ${false}
      ${trees} | ${'README.md'} | ${true}
      ${trees} | ${'readme.md'} | ${false}
    `('returns $expected when searching for "$childName"', ({ tree, childName, expected }) => {
      expect(directoryContainsChild({ trees: tree }, childName)).toBe(expected);
    });
  });

  describe('shouldStopPagination', () => {
    it.each`
      page                 | isLoading | expected
      ${FTB_MAX_PAGES}     | ${false}  | ${true}
      ${1}                 | ${true}   | ${true}
      ${FTB_MAX_PAGES - 1} | ${false}  | ${false}
      ${FTB_MAX_PAGES}     | ${true}   | ${true}
    `(
      'returns $expected when page=$page and isLoading=$isLoading',
      ({ page, isLoading, expected }) => {
        expect(shouldStopPagination(page, isLoading)).toBe(expected);
      },
    );
  });

  describe('hasMorePages', () => {
    it.each`
      pageInfo                  | expected
      ${{ hasNextPage: true }}  | ${true}
      ${{ hasNextPage: false }} | ${false}
      ${undefined}              | ${false}
      ${null}                   | ${false}
    `('returns $expected when pageInfo=$pageInfo', ({ pageInfo, expected }) => {
      expect(hasMorePages({ pageInfo })).toBe(expected);
    });
  });

  describe('isExpandable', () => {
    it.each`
      segments                                       | expected
      ${['src', 'components']}                       | ${true}
      ${['a']}                                       | ${true}
      ${[]}                                          | ${false}
      ${new Array(FTB_MAX_DEPTH + 1).fill('folder')} | ${false}
      ${new Array(FTB_MAX_DEPTH).fill('folder')}     | ${true}
    `('returns $expected for segments length $segments.length', ({ segments, expected }) => {
      expect(isExpandable(segments)).toBe(expected);
    });
  });

  describe('handleTreeKeydown', () => {
    let container;
    let items;

    const triggerKey = (key, fromIndex) => {
      const event = new KeyboardEvent('keydown', { key, bubbles: true });
      Object.defineProperty(event, 'target', { value: items[fromIndex], enumerable: true });
      Object.defineProperty(event, 'currentTarget', { value: container, enumerable: true });
      items[fromIndex].focus();
      handleTreeKeydown(event);
      return event;
    };

    beforeEach(() => {
      container = document.createElement('div');
      container.setAttribute('role', 'tree');
      container.innerHTML = `
      <button role="treeitem">Item 0</button>
      <button role="treeitem">Item 1</button>
      <button role="treeitem">Item 2</button>
    `;
      document.body.appendChild(container);
      items = container.querySelectorAll('[role="treeitem"]');
    });

    afterEach(() => document.body.removeChild(container));

    describe.each`
      key            | from | to
      ${'ArrowDown'} | ${0} | ${1}
      ${'ArrowUp'}   | ${1} | ${0}
      ${'ArrowUp'}   | ${0} | ${0}
      ${'ArrowDown'} | ${2} | ${2}
    `('$key from item $from', ({ key, from, to }) => {
      it(`moves focus to item ${to}`, () => {
        triggerKey(key, from);

        expect(document.activeElement).toBe(items[to]);
      });
    });
  });
});
