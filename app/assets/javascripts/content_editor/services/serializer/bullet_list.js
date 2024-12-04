import { preserveUnchanged } from '../serialization_helpers';

/**
 * We extracted this function from
 * https://github.com/ProseMirror/prosemirror-markdown/blob/master/src/to_markdown.ts#L350.
 *
 * We need to overwrite this function because we don’t want to wrap the list item nodes
 * with the bullet delimiter when the list item node hasn’t changed
 */
// eslint-disable-next-line max-params
export const renderList = (state, node, delim, firstDelim) => {
  if (state.closed && state.closed.type === node.type) state.flushClose(3);
  else if (state.inTightList) state.flushClose(1);

  const isTight =
    typeof node.attrs.tight !== 'undefined' ? node.attrs.tight : state.options.tightLists;
  const prevTight = state.inTightList;

  state.inTightList = isTight;

  node.forEach((child, _, i) => {
    const same = state.options.changeTracker.get(child);

    if (i && isTight) {
      state.flushClose(1);
    }

    if (same) {
      // Avoid wrapping list item when node hasn’t changed
      state.render(child, node, i);
    } else {
      state.wrapBlock(delim, firstDelim(i), node, () => state.render(child, node, i));
    }
  });

  state.inTightList = prevTight;
};

export const renderBulletList = (state, node) => {
  const { sourceMarkdown, bullet: bulletAttr } = node.attrs;
  const bullet = /^(\*|\+|-)\s/.exec(sourceMarkdown?.trim())?.[1] || bulletAttr || '*';

  renderList(state, node, '  ', () => `${bullet} `);
};

const bulletList = preserveUnchanged(renderBulletList);

export default bulletList;
