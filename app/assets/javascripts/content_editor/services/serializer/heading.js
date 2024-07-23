import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';
import { preserveUnchanged } from '../serialization_helpers';

const heading = preserveUnchanged((state, node) => {
  if (state.options.skipEmptyNodes && !node.childCount) return;

  defaultMarkdownSerializer.nodes.heading(state, node);
});

export default heading;
