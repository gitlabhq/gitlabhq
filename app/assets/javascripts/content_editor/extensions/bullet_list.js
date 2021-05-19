import { BulletList } from '@tiptap/extension-bullet-list';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

export const tiptapExtension = BulletList;
export const serializer = defaultMarkdownSerializer.nodes.bullet_list;
