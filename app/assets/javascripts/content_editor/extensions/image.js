import { Image } from '@tiptap/extension-image';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import ImageWrapper from '../components/wrappers/image.vue';

const resolveImageEl = (element) =>
  element.nodeName === 'IMG' ? element : element.querySelector('img');

export default Image.extend({
  defaultOptions: {
    ...Image.options,
    inline: true,
  },
  addAttributes() {
    return {
      ...this.parent?.(),
      uploading: {
        default: false,
      },
      src: {
        default: null,
        /*
         * GitLab Flavored Markdown provides lazy loading for rendering images. As
         * as result, the src attribute of the image may contain an embedded resource
         * instead of the actual image URL. The image URL is moved to the data-src
         * attribute.
         */
        parseHTML: (element) => {
          const img = resolveImageEl(element);

          return {
            src: img.dataset.src || img.getAttribute('src'),
          };
        },
      },
      canonicalSrc: {
        default: null,
        parseHTML: (element) => {
          return {
            canonicalSrc: element.dataset.canonicalSrc,
          };
        },
      },
      alt: {
        default: null,
        parseHTML: (element) => {
          const img = resolveImageEl(element);

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
  addNodeView() {
    return VueNodeViewRenderer(ImageWrapper);
  },
});
