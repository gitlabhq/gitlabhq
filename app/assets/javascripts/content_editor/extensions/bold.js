import { Bold } from '@tiptap/extension-bold';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

export const tiptapExtension = Bold;
export const serializer = defaultMarkdownSerializer.marks.strong;
