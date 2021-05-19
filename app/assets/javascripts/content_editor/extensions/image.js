import { Image } from '@tiptap/extension-image';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

const ExtendedImage = Image.extend({
  defaultOptions: { inline: true },
});

export const tiptapExtension = ExtendedImage;
export const serializer = defaultMarkdownSerializer.nodes.image;
