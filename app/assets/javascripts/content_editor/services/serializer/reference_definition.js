import ReferenceDefinition from '../../extensions/reference_definition';
import { preserveUnchanged } from '../serialization_helpers';

const referenceDefinition = preserveUnchanged({
  // eslint-disable-next-line max-params
  render: (state, node, parent, index, same, sourceMarkdown) => {
    const nextSibling = parent.maybeChild(index + 1);

    state.text(same ? sourceMarkdown : node.textContent, false);

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
  },
  overwriteSourcePreservationStrategy: true,
});

export default referenceDefinition;
