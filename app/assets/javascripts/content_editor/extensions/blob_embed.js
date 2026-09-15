import { Node } from '@tiptap/core';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import BlobEmbedWrapper from '../components/wrappers/blob_embed.vue';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

export default Node.create({
  name: 'blobEmbed',

  group: 'block',

  atom: true,

  addAttributes() {
    return {
      url: {
        default: null,
        parseHTML: (element) => element.querySelector('a.blob-embed-title')?.getAttribute('href'),
      },
      text: {
        default: null,
        parseHTML: (element) => element.querySelector('a.blob-embed-title')?.textContent,
      },
      range: {
        default: '',
        parseHTML: (element) => element.querySelector('.blob-embed-range')?.textContent,
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'div.blob-embed',
        priority: PARSE_HTML_PRIORITY_HIGHEST,
      },
    ];
  },

  renderHTML({ node }) {
    return [
      'div',
      { class: 'blob-embed' },
      ['a', { class: 'blob-embed-title', href: node.attrs.url }, node.attrs.text || node.attrs.url],
      ['span', { class: 'blob-embed-range' }, node.attrs.range],
    ];
  },

  addNodeView() {
    return new VueNodeViewRenderer(BlobEmbedWrapper);
  },
});
