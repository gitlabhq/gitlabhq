import { BulletList } from '@tiptap/extension-bullet-list';
import { getMarkdownSource } from '../services/markdown_sourcemap';

export default BulletList.extend({
  addOptions() {
    return {
      ...this.parent?.(),
      HTMLAttributes: {
        dir: 'auto',
      },
    };
  },

  addAttributes() {
    return {
      ...this.parent?.(),

      bullet: {
        default: '*',
        parseHTML(element) {
          const bullet = getMarkdownSource(element)?.trim().charAt(0);

          return '*+-'.includes(bullet) ? bullet : '*';
        },
      },
    };
  },
});
