import { Node } from '@tiptap/core';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import HTMLCommentWrapper from '../components/wrappers/html_comment.vue';

export const hexHTMLEntityRegex = /&#x([0-9A-F]{2,4});/gi;

export default Node.create({
  name: 'htmlComment',
  group: 'block',
  selectable: true,
  atom: true,

  addAttributes() {
    return {
      description: {
        default: null,
        parseHTML(element) {
          return (
            element.textContent.replace(hexHTMLEntityRegex, (_, code) =>
              String.fromCharCode(parseInt(code, 16)),
            ) || ' '
          ).trim();
        },
      },
    };
  },

  parseHTML() {
    return [{ tag: 'comment' }];
  },

  addNodeView() {
    return VueNodeViewRenderer(HTMLCommentWrapper);
  },
});
