import { ListItem } from '@tiptap/extension-list-item';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

export const tiptapExtension = ListItem;
export const serializer = defaultMarkdownSerializer.nodes.list_item;
