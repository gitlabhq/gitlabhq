import { OrderedList } from '@tiptap/extension-ordered-list';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

export const tiptapExtension = OrderedList;
export const serializer = defaultMarkdownSerializer.nodes.ordered_list;
