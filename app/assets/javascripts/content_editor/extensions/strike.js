import { Strike } from '@tiptap/extension-strike';

export const tiptapExtension = Strike;
export const serializer = {
  open: '~~',
  close: '~~',
  mixable: true,
  expelEnclosingWhitespace: true,
};
