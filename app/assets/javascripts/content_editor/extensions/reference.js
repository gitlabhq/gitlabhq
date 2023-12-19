import { Node, InputRule } from '@tiptap/core';
import { VueNodeViewRenderer } from '@tiptap/vue-2';
import ReferenceWrapper from '../components/wrappers/reference.vue';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

const getAnchor = (element) => {
  if (element.nodeName === 'A') return element;
  return element.querySelector('a');
};

const findReference = (editor, reference) => {
  let position;

  editor.view.state.doc.descendants((descendant, pos) => {
    if (descendant.isText && descendant.text.includes(reference)) {
      position = pos + descendant.text.indexOf(reference);
      return false;
    }

    return true;
  });

  return position;
};

export default Node.create({
  name: 'reference',

  inline: true,

  group: 'inline',

  atom: true,

  addOptions() {
    return {
      assetResolver: null,
    };
  },

  addAttributes() {
    return {
      className: {
        default: null,
        parseHTML: (element) => getAnchor(element).className,
      },
      referenceType: {
        default: null,
        parseHTML: (element) => getAnchor(element).dataset.referenceType,
      },
      originalText: {
        default: null,
        parseHTML: (element) => getAnchor(element).dataset.original,
      },
      href: {
        default: null,
        parseHTML: (element) => getAnchor(element).getAttribute('href'),
      },
      text: {
        default: null,
        parseHTML: (element) => getAnchor(element).textContent,
      },
    };
  },

  addCommands() {
    return {
      insertQuickAction: () => ({ commands }) => commands.insertContent('<p>/</p>'),
    };
  },

  addInputRules() {
    const { editor } = this;
    const { assetResolver } = this.options;
    const referenceInputRegex = /(?:^|\s)([\w/]*([#!&%$@~]|\[vulnerability:)[\w.]+(\+?s?\]?))(?:\s|\n)/m;
    const referenceTypes = {
      '#': 'issue',
      '!': 'merge_request',
      '&': 'epic',
      '%': 'milestone',
      $: 'snippet',
      '@': 'user',
      '~': 'label',
      '[vulnerability:': 'vulnerability',
    };
    const nodeTypes = {
      label: editor.schema.nodes.referenceLabel,
      default: editor.schema.nodes.reference,
    };

    return [
      new InputRule({
        find: referenceInputRegex,
        handler: async ({ match }) => {
          const [, referenceId, referenceSymbol, expansionType] = match;
          const referenceType = referenceTypes[referenceSymbol];

          const {
            href,
            text,
            expandedText,
            fullyExpandedText,
            backgroundColor,
          } = await assetResolver.resolveReference(referenceId);

          if (!text) return;

          let referenceText = text;
          if (expansionType === '+') referenceText = expandedText || text;
          if (expansionType === '+s') referenceText = fullyExpandedText || text;

          const position = findReference(editor, referenceId);
          if (!position) return;

          const nodeType = nodeTypes[referenceType] || nodeTypes.default;

          editor.view.dispatch(
            editor.state.tr.replaceWith(position, position + referenceId.length, [
              nodeType.create({
                referenceType,
                originalText: referenceId,
                color: backgroundColor,
                href,
                text: referenceText,
              }),
            ]),
          );
        },
      }),
    ];
  },

  parseHTML() {
    return [
      {
        tag: 'a.gfm:not([data-link=true])',
        priority: PARSE_HTML_PRIORITY_HIGHEST,
      },
    ];
  },

  renderHTML({ node }) {
    return [
      'gl-reference',
      {
        'data-reference-type': node.attrs.referenceType,
        'data-original-text': node.attrs.originalText,
        href: node.attrs.href,
        text: node.attrs.text,
      },
      node.attrs.text,
    ];
  },

  addNodeView() {
    return new VueNodeViewRenderer(ReferenceWrapper);
  },
});
