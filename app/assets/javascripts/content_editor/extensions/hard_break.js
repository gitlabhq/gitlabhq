import { HardBreak } from '@tiptap/extension-hard-break';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

export const tiptapExtension = HardBreak;
export const serializer = defaultMarkdownSerializer.nodes.hard_break;
