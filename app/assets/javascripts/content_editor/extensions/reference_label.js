import { VueNodeViewRenderer } from '@tiptap/vue-2';
import { SCOPED_LABEL_DELIMITER } from '~/sidebar/components/labels/labels_select_widget/constants';
import LabelWrapper from '../components/wrappers/reference_label.vue';
import Reference from './reference';

export default Reference.extend({
  name: 'reference_label',

  addAttributes() {
    return {
      ...this.parent(),
      text: {
        default: null,
        parseHTML: (element) => {
          const text = element.querySelector('.gl-label-text').textContent;
          const scopedText = element.querySelector('.gl-label-text-scoped')?.textContent;
          if (!scopedText) return text;
          return `${text}${SCOPED_LABEL_DELIMITER}${scopedText}`;
        },
      },
      color: {
        default: null,
        parseHTML: (element) => element.querySelector('.gl-label-text').style.backgroundColor,
      },
    };
  },

  parseHTML() {
    return [{ tag: 'span.gl-label' }];
  },

  addNodeView() {
    return new VueNodeViewRenderer(LabelWrapper);
  },
});
