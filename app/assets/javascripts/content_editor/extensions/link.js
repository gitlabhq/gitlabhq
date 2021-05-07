import { Link } from '@tiptap/extension-link';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

export const tiptapExtension = Link;
export const serializer = defaultMarkdownSerializer.marks.link;
