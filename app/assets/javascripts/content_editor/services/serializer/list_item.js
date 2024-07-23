import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';
import { preserveUnchanged } from '../serialization_helpers';

const listItem = preserveUnchanged(defaultMarkdownSerializer.nodes.list_item);

export default listItem;
