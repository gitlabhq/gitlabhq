import { ALERT_TYPES } from '../constants/alert_types';
import Blockquote from './blockquote';

const alertTypes = Object.values(ALERT_TYPES);

export default Blockquote.extend({
  name: 'alert',
  content: 'alertTitle block*',
  isolating: true,

  addAttributes() {
    return {
      type: {
        default: ALERT_TYPES.NOTE,
        parseHTML: (element) => {
          return alertTypes.find((type) => element.classList.contains(`markdown-alert-${type}`));
        },
        renderHTML: (HTMLAttributes) => {
          return { class: `markdown-alert markdown-alert-${HTMLAttributes.type}` };
        },
      },
    };
  },

  parseHTML() {
    return [{ tag: 'div.markdown-alert' }];
  },

  renderHTML({ HTMLAttributes }) {
    return ['div', HTMLAttributes, 0];
  },

  addCommands() {
    return {
      insertAlert:
        () =>
        ({ commands }) =>
          commands.insertContent({
            type: this.name,
            attrs: { type: ALERT_TYPES.NOTE },
            content: [{ type: 'alertTitle' }, { type: 'paragraph' }],
          }),
    };
  },
});
