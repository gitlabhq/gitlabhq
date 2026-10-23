const defaultChildrenOf = (node) => node.children ?? [];

/**
 * Flattens a tree of table rows into the rows to render, in order. A collapsed node's
 * descendants are left out, so each visible child renders as its own row under its parent.
 *
 * @param {Array} nodes Top-level nodes.
 * @param {Object} options
 * @param {Function} options.keyOf Returns a node's key, unique across the whole tree.
 * @param {Function} [options.childrenOf] Returns a node's children. Defaults to `node.children`.
 * @param {Function} [options.isExpandable] Whether a node can expand. Defaults to having
 *   children; override it when children load only after the first expand.
 * @param {Set} [options.expandedKeys] Keys of the expanded nodes.
 * @returns {Array<{ node, key, depth, parentKey, expandable, expanded, childKeys }>}
 */
export const flattenTree = (
  nodes,
  {
    keyOf,
    childrenOf = defaultChildrenOf,
    isExpandable = (node) => childrenOf(node).length > 0,
    expandedKeys = new Set(),
  },
) => {
  const rows = [];

  const visit = (siblings, depth, parentKey) => {
    siblings.forEach((node) => {
      const key = keyOf(node);
      const children = childrenOf(node);
      const expandable = isExpandable(node);
      const expanded = expandable && expandedKeys.has(key);

      rows.push({
        node,
        key,
        depth,
        parentKey,
        expandable,
        expanded,
        childKeys: children.map(keyOf),
      });

      if (expanded) visit(children, depth + 1, key);
    });
  };

  visit(nodes, 0, null);

  return rows;
};

/**
 * Sorts each level of a tree on its own, so a child never moves out from under its parent.
 * Returns new arrays and leaves `nodes` untouched.
 *
 * @param {Array} nodes Top-level nodes.
 * @param {Function} compare An `Array.prototype.sort` comparator.
 * @param {Object} [options]
 * @param {Function} [options.childrenOf] Returns a node's children. Defaults to `node.children`.
 * @param {Function} [options.withChildren] Returns a copy of a node holding the given children.
 *   Defaults to setting `children`.
 */
export const sortTree = (
  nodes,
  compare,
  {
    childrenOf = defaultChildrenOf,
    withChildren = (node, children) => ({ ...node, children }),
  } = {},
) =>
  nodes.toSorted(compare).map((node) => {
    const children = childrenOf(node);
    if (!children.length) return node;

    return withChildren(node, sortTree(children, compare, { childrenOf, withChildren }));
  });

/**
 * A DOM id for a row, for a disclosure toggle's `aria-controls`. Encoding keeps it free of
 * spaces, which would split it into several ids there, and keeps distinct keys distinct.
 */
export const rowDomId = (prefix, key) => `${prefix}-${encodeURIComponent(key)}`;
