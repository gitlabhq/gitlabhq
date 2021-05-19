import { Code } from '@tiptap/extension-code';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

export const tiptapExtension = Code;
export const serializer = defaultMarkdownSerializer.marks.code;
