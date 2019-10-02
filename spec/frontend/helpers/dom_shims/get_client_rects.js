function hasHiddenStyle(node) {
  if (!node.style) {
    return false;
  } else if (node.style.display === 'none' || node.style.visibility === 'hidden') {
    return true;
  }

  return false;
}

function createDefaultClientRect() {
  return {
    bottom: 0,
    height: 0,
    left: 0,
    right: 0,
    top: 0,
    width: 0,
    x: 0,
    y: 0,
  };
}

/**
 * This is needed to get the `toBeVisible` matcher to work in `jsdom`
 *
 * Reference:
 * - https://github.com/jsdom/jsdom/issues/1322
 * - https://github.com/unindented/custom-jquery-matchers/blob/v2.1.0/packages/custom-jquery-matchers/src/matchers.js#L157
 */
window.Element.prototype.getClientRects = function getClientRects() {
  let node = this;

  while (node) {
    if (node === document) {
      break;
    }

    if (hasHiddenStyle(node)) {
      return [];
    }
    node = node.parentNode;
  }

  if (!node) {
    return [];
  }

  return [createDefaultClientRect()];
};
