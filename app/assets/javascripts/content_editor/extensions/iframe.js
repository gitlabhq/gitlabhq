import { Node } from '@tiptap/core';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import { isIframeSrcAllowed } from '~/behaviors/markdown/render_iframe';
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
        parseHTML: (element) => element.dataset.iframeSrc,
      },
      canonicalSrc: {
        default: null,
        parseHTML: (element) => element.dataset.iframeCanonicalSrc,
      },
      providerId: {
        default: null,
        parseHTML: (element) => element.dataset.iframeProviderId,
      },
      alt: {
        default: null,
        parseHTML: (element) => element.dataset.title,
      },
      width: {
        default: null,
        parseHTML: (element) => element.dataset.width,
      },
      height: {
        default: null,
        parseHTML: (element) => element.dataset.height,
      },
    };
  },

  parseHTML() {
    return [
      {
        priority: PARSE_HTML_PRIORITY_HIGHEST,
        tag: 'span.js-render-iframe',
        getAttrs: (element) =>
          isIframeSrcAllowed(element.dataset.iframeSrc, element.dataset.iframeProviderId)
            ? null
            : false,
      },
    ];
  },

  renderHTML({ node }) {
    const { src, canonicalSrc, providerId, alt, width, height } = node.attrs;

    return [
      'span',
      {
        class: 'media-container iframe-container js-render-iframe',
        'data-iframe-src': src,
        'data-iframe-canonical-src': canonicalSrc,
        'data-iframe-provider-id': providerId,
        'data-title': alt,
        'data-width': width,
        'data-height': height,
      },
      ['a', { href: canonicalSrc }, alt || canonicalSrc],
    ];
  },

  addNodeView() {
    return VueNodeViewRenderer(IframeWrapper);
  },
});
