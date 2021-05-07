import { Blockquote } from '@tiptap/extension-blockquote';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

export const tiptapExtension = Blockquote;
export const serializer = defaultMarkdownSerializer.nodes.blockquote;
