import { Image } from '@tiptap/extension-image';
import { defaultMarkdownSerializer } from 'prosemirror-markdown/src/to_markdown';

const ExtendedImage = Image.extend({
  addAttributes() {
    return {
      ...this.parent?.(),
      src: {
        default: null,
        /*
         * GitLab Flavored Markdown provides lazy loading for rendering images. As
         * as result, the src attribute of the image may contain an embedded resource
         * instead of the actual image URL. The image URL is moved to the data-src
         * attribute.
         */
        parseHTML: (element) => {
          const img = element.querySelector('img');

          return {
            src: img.dataset.src || img.getAttribute('src'),
          };
        },
      },
      alt: {
        default: null,
        parseHTML: (element) => {
          const img = element.querySelector('img');

          return {
            alt: img.getAttribute('alt'),
          };
        },
      },
    };
  },
  parseHTML() {
    return [
      {
        priority: 100,
        tag: 'a.no-attachment-icon',
      },
      {
        tag: 'img[src]',
      },
    ];
  },
});

const serializer = defaultMarkdownSerializer.nodes.image;

export const configure = ({ renderMarkdown, uploadsPath }) => {
  return {
    tiptapExtension: ExtendedImage.configure({ inline: true, renderMarkdown, uploadsPath }),
    serializer,
  };
};
