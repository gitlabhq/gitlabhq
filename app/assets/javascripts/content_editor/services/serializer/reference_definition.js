import ReferenceDefinition from '../../extensions/reference_definition';

// eslint-disable-next-line max-params
function referenceDefinition(state, node, parent, index) {
  const nextSibling = parent.maybeChild(index + 1);

  state.text(node.textContent, false);

  /**
   * Do not insert a blank line between reference definitions
   * because it isn’t necessary and a more compact text format
   * is preferred.
   */
  if (!nextSibling || nextSibling.type.name !== ReferenceDefinition.name) {
    state.closeBlock(node);
  } else {
    state.ensureNewLine();
  }
}

export default referenceDefinition;
