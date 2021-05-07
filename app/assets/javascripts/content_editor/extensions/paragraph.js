import { Paragraph } from '@tiptap/extension-paragraph';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

export const tiptapExtension = Paragraph;
export const serializer = defaultMarkdownSerializer.nodes.paragraph;
