function hasHiddenStyle(node) {
  if (!node.style) {
    return false;
  }
  if (node.style.display === 'none' || node.style.visibility === 'hidden') {
    return true;
  }

  return false;
}

function createDefaultClientRect(node) {
  const { outerWidth: width, outerHeight: height } = node;

  return {
    bottom: height,
    height,
    left: 0,
    right: width,
    top: 0,
    width,
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

  return [createDefaultClientRect(node)];
};
