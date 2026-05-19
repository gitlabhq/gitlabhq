import { Node } from '@tiptap/core';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';
import IframeWrapper from '../components/wrappers/iframe.vue';

export default Node.create({
  name: 'iframe',
  group: 'inline',
  inline: true,
  draggable: true,

  addAttributes() {
    return {
      src: {
        default: null,
        parseHTML: (element) => {
          const img = element.querySelector('img.js-render-iframe');
          return img.getAttribute('src');
        },
      },
      canonicalSrc: {
        default: null,
        parseHTML: (element) => {
          const img = element.querySelector('img.js-render-iframe');
          return (
            img.dataset.iframeCanonicalSrc || img.dataset.canonicalSrc || img.getAttribute('src')
          );
        },
      },
      alt: {
        default: null,
        parseHTML: (element) => {
          const img = element.querySelector('img.js-render-iframe');
          return img.dataset.title || img.getAttribute('alt');
        },
      },
      width: {
        default: null,
        parseHTML: (element) => {
          const img = element.querySelector('img.js-render-iframe');
          return img.getAttribute('width');
        },
      },
      height: {
        default: null,
        parseHTML: (element) => {
          const img = element.querySelector('img.js-render-iframe');
          return img.getAttribute('height');
        },
      },
    };
  },

  parseHTML() {
    return [
      {
        priority: PARSE_HTML_PRIORITY_HIGHEST,
        tag: 'span.media-container.img-container',
        getAttrs: (element) => {
          const img = element.querySelector('img.js-render-iframe');
          if (!img) return false;
          return null;
        },
      },
    ];
  },

  renderHTML({ node }) {
    return [
      'span',
      { class: 'media-container img-container' },
      [
        'img',
        {
          class: 'js-render-iframe',
          src: node.attrs.src,
          'data-iframe-canonical-src': node.attrs.canonicalSrc,
          'data-title': node.attrs.alt,
          width: node.attrs.width,
          height: node.attrs.height,
        },
      ],
    ];
  },

  addNodeView() {
    return VueNodeViewRenderer(IframeWrapper);
  },
});
