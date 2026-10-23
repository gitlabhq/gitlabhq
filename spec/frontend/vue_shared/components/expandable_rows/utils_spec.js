import { flattenTree, rowDomId, sortTree } from '~/vue_shared/components/expandable_rows/utils';

const keyOf = (node) => node.id;
const keysOf = (rows) => rows.map(({ key }) => key);

const tree = [
  {
    id: 'a',
    value: 2,
    children: [
      { id: 'a1', value: 5, children: [{ id: 'a1x', value: 1 }] },
      { id: 'a2', value: 3 },
    ],
  },
  { id: 'b', value: 1 },
];

describe('expandable rows utils', () => {
  describe('flattenTree', () => {
    it('returns only top-level rows when nothing is expanded', () => {
      const rows = flattenTree(tree, { keyOf });

      expect(rows).toEqual([
        {
          node: tree[0],
          key: 'a',
          depth: 0,
          parentKey: null,
          expandable: true,
          expanded: false,
          childKeys: ['a1', 'a2'],
        },
        {
          node: tree[1],
          key: 'b',
          depth: 0,
          parentKey: null,
          expandable: false,
          expanded: false,
          childKeys: [],
        },
      ]);
    });

    it('places the children of an expanded row right after it', () => {
      const rows = flattenTree(tree, { keyOf, expandedKeys: new Set(['a']) });

      expect(keysOf(rows)).toEqual(['a', 'a1', 'a2', 'b']);
      expect(rows[1]).toMatchObject({ depth: 1, parentKey: 'a', expandable: true });
    });

    it('renders nested levels when every ancestor is expanded', () => {
      const rows = flattenTree(tree, { keyOf, expandedKeys: new Set(['a', 'a1']) });

      expect(keysOf(rows)).toEqual(['a', 'a1', 'a1x', 'a2', 'b']);
      expect(rows[2]).toMatchObject({ depth: 2, parentKey: 'a1' });
    });

    it('hides descendants of a collapsed row even when they are expanded', () => {
      const rows = flattenTree(tree, { keyOf, expandedKeys: new Set(['a1']) });

      expect(keysOf(rows)).toEqual(['a', 'b']);
    });

    it('uses `childrenOf` and `isExpandable` when given', () => {
      const nodes = [{ id: 'p', rows: [] }];
      const rows = flattenTree(nodes, {
        keyOf,
        childrenOf: (node) => node.rows,
        isExpandable: () => true,
        expandedKeys: new Set(['p']),
      });

      expect(rows).toEqual([
        expect.objectContaining({ key: 'p', expandable: true, expanded: true }),
      ]);
    });

    it('never marks a row expanded when it cannot expand', () => {
      const rows = flattenTree(tree, { keyOf, expandedKeys: new Set(['b']) });

      expect(rows[1].expanded).toBe(false);
    });
  });

  describe('sortTree', () => {
    const byValue = (a, b) => a.value - b.value;

    it('sorts each level without moving children out from under their parent', () => {
      const sorted = sortTree(tree, byValue);

      expect(sorted.map(keyOf)).toEqual(['b', 'a']);
      expect(sorted[1].children.map(keyOf)).toEqual(['a2', 'a1']);
      expect(sorted[1].children[1].children.map(keyOf)).toEqual(['a1x']);
    });

    it('does not mutate the input', () => {
      sortTree(tree, byValue);

      expect(tree.map(keyOf)).toEqual(['a', 'b']);
      expect(tree[0].children.map(keyOf)).toEqual(['a1', 'a2']);
    });

    it('uses `childrenOf` and `withChildren` when given', () => {
      const nodes = [
        {
          id: 'p',
          rows: [
            { id: 'y', value: 2 },
            { id: 'x', value: 1 },
          ],
        },
      ];
      const sorted = sortTree(nodes, byValue, {
        childrenOf: (node) => node.rows ?? [],
        withChildren: (node, rows) => ({ ...node, rows }),
      });

      expect(sorted[0].rows.map(keyOf)).toEqual(['x', 'y']);
    });
  });

  describe('rowDomId', () => {
    it('returns an id without spaces', () => {
      expect(rowDomId('row', '["Not set", 1]')).not.toContain(' ');
    });

    it('keeps distinct keys distinct', () => {
      expect(rowDomId('row', 'a b')).not.toBe(rowDomId('row', 'a_b'));
    });
  });
});
