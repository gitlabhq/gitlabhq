import { Node } from '@tiptap/core';
import { Fragment } from '@tiptap/pm/model';

export default Node.create({
  name: 'time',
  inline: true,
  group: 'inline',

  content: 'text*',
  marks: '',

  addAttributes() {
    return {
      title: {
        default: null,
        parseHTML: (element) => element.getAttribute('title') || element.textContent,
      },
      datetime: {
        default: null,
        parseHTML: (element) => element.getAttribute('datetime'),
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'time',
        getContent(element, schema) {
          return Fragment.from(schema.text(element.getAttribute('title') || element.textContent));
        },
      },
    ];
  },

  renderHTML({ node }) {
    return ['time', { title: node.attrs.title, datetime: node.attrs.datetime }, 0];
  },
});
