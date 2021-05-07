import { HorizontalRule } from '@tiptap/extension-horizontal-rule';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

export const tiptapExtension = HorizontalRule;
export const serializer = defaultMarkdownSerializer.nodes.horizontal_rule;
