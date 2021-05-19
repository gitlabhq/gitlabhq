import { Heading } from '@tiptap/extension-heading';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

export const tiptapExtension = Heading;
export const serializer = defaultMarkdownSerializer.nodes.heading;
