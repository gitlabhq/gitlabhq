import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';
import { preserveUnchanged } from '../serialization_helpers';

const horizontalRule = preserveUnchanged(defaultMarkdownSerializer.nodes.horizontal_rule);

export default horizontalRule;
