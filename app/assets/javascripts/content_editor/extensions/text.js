import { Text } from '@tiptap/extension-text';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

export const tiptapExtension = Text;
export const serializer = defaultMarkdownSerializer.nodes.text;
