import Paragraph from '@tiptap/extension-paragraph';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import { Fragment } from '@tiptap/pm/model';
import AlertTitleWrapper from '../components/wrappers/alert_title.vue';
import { DEFAULT_ALERT_TITLES } from '../constants/alert_types';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

const defaultAlertTitles = Object.values(DEFAULT_ALERT_TITLES);

export default Paragraph.extend({
  name: 'alertTitle',
  group: 'alert',
  content: 'text*',
  marks: '',

  parseHTML() {
    return [
      {
        tag: '.markdown-alert-title',
        priority: PARSE_HTML_PRIORITY_HIGHEST,
        getContent(element, schema) {
          return defaultAlertTitles.includes(element.textContent)
            ? Fragment.empty
            : Fragment.from(schema.text(element.textContent));
        },
      },
    ];
  },

  renderHTML({ HTMLAttributes }) {
    return ['p', { ...HTMLAttributes, class: 'markdown-alert-title' }, 0];
  },

  addNodeView() {
    return VueNodeViewRenderer(AlertTitleWrapper);
  },
});
