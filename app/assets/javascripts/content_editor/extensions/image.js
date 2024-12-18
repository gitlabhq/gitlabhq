import { Image } from '@tiptap/extension-image';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import { PARSE_HTML_PRIORITY_HIGH } from '../constants';
import ImageWrapper from '../components/wrappers/image.vue';
import { getSourceMapAttributes } from '../services/markdown_sourcemap';

const resolveImageEl = (element) =>
  element.nodeName === 'IMG' ? element : element.querySelector('img');

export default Image.extend({
  draggable: true,

  addOptions() {
    return {
      ...this.parent?.(),
      inline: true,
    };
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

          return img.dataset.src || img.getAttribute('src');
        },
      },
      canonicalSrc: {
        default: null,
        parseHTML: (element) => element.dataset.canonicalSrc,
        renderHTML: () => '',
      },
      alt: {
        default: null,
        parseHTML: (element) => {
          const img = resolveImageEl(element);

          return img.getAttribute('alt');
        },
      },
      title: {
        default: null,
        parseHTML: (element) => {
          const img = resolveImageEl(element);

          return img.getAttribute('title');
        },
      },
      width: {
        default: null,
        parseHTML: (element) => {
          const img = resolveImageEl(element);

          return img.getAttribute('width');
        },
      },
      height: {
        default: null,
        parseHTML: (element) => {
          const img = resolveImageEl(element);

          return img.getAttribute('height');
        },
      },
      isReference: {
        default: false,
        renderHTML: () => '',
      },
      ...getSourceMapAttributes(resolveImageEl),
    };
  },
  parseHTML() {
    return [
      {
        priority: PARSE_HTML_PRIORITY_HIGH,
        tag: 'a.no-attachment-icon',
      },
      {
        tag: 'img[src]',
      },
    ];
  },
  renderHTML({ HTMLAttributes }) {
    return [
      'img',
      {
        src: HTMLAttributes.src,
        alt: HTMLAttributes.alt,
        title: HTMLAttributes.title,
        width: HTMLAttributes.width,
        height: HTMLAttributes.height,
      },
    ];
  },
  addNodeView() {
    return VueNodeViewRenderer(ImageWrapper);
  },
});
