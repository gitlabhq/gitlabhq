import { Node, InputRule } from '@tiptap/core';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';
import PlaceholderWrapper from '../components/wrappers/placeholder.vue';

const PLACEHOLDER_SYNTAX = /%\{[\p{Alphabetic}\p{M}\p{Pc}\p{Nd}\p{Join_Control}]{1,30}\}/u.source;
const PLACEHOLDER_REGEX = new RegExp(`^${PLACEHOLDER_SYNTAX}$`, 'u');
const PLACEHOLDER_INPUT_REGEX = new RegExp(`${PLACEHOLDER_SYNTAX}$`, 'u');

const isPlaceholder = (element) => {
  const [child, ...rest] = element.childNodes;

  if (rest.length > 0 || (child && child.nodeType !== window.Node.TEXT_NODE)) return false;

  return PLACEHOLDER_REGEX.test(element.dataset.placeholder || element.textContent);
};

const trackPosition = (editor, initialPosition) => {
  const tracked = { position: initialPosition };
  const map = ({ transaction }) => {
    tracked.position = transaction.mapping.map(tracked.position);
  };

  editor.on('transaction', map);
  tracked.stop = () => editor.off('transaction', map);

  return tracked;
};

const isInCode = (doc, from, to) => {
  let inCode = false;

  doc.nodesBetween(from, to, (node) => {
    if (node.type.spec.code || node.marks.some((mark) => mark.type.spec.code)) inCode = true;
  });

  return inCode;
};

export default Node.create({
  name: 'placeholder',
  inline: true,
  group: 'inline',

  addOptions() {
    return {
      assetResolver: null,
    };
  },

  addAttributes() {
    return {
      placeholder: {
        default: null,
        parseHTML: (element) => element.dataset.placeholder || element.textContent,
      },
      value: {
        default: null,
        parseHTML: (element) => (element.dataset.placeholder && element.textContent) || null,
      },
    };
  },

  parseHTML() {
    return [
      {
        tag: 'span[data-placeholder]',
        priority: PARSE_HTML_PRIORITY_HIGHEST,
        getAttrs: (element) => (isPlaceholder(element) ? null : false),
      },
    ];
  },

  renderHTML({ node }) {
    const { placeholder, value } = node.attrs;

    return value
      ? ['span', { 'data-placeholder': placeholder }, value]
      : ['span', { 'data-placeholder': '' }, placeholder];
  },

  addInputRules() {
    if (!window.gon.features?.markdownPlaceholders) return [];

    const { editor } = this;
    const { assetResolver } = this.options;

    return [
      new InputRule({
        find: PLACEHOLDER_INPUT_REGEX,
        handler: async ({ match, range }) => {
          const [placeholder] = match;
          const tracked = trackPosition(editor, range.from);

          const attrs = await assetResolver.resolvePlaceholder(placeholder).finally(tracked.stop);
          if (!attrs) return;

          const { doc } = editor.state;
          const from = tracked.position;
          const to = from + placeholder.length;
          if (to > doc.content.size || doc.textBetween(from, to) !== placeholder) return;
          if (isInCode(doc, from, to)) return;

          editor.view.dispatch(
            editor.state.tr.replaceWith(from, to, [
              editor.schema.nodes.placeholder.create(attrs, null, doc.nodeAt(from).marks),
            ]),
          );
        },
      }),
    ];
  },

  addNodeView() {
    return VueNodeViewRenderer(PlaceholderWrapper);
  },
});
