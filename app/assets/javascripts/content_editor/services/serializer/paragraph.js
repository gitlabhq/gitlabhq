import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';
import { preserveUnchanged } from '../serialization_helpers';

const paragraph = preserveUnchanged(defaultMarkdownSerializer.nodes.paragraph);

export default paragraph;
