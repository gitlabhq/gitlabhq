import { Node } from '@tiptap/core';
import { Plugin, PluginKey } from '@tiptap/pm/state';
import { Decoration, DecorationSet } from '@tiptap/pm/view';
import { isValidColorExpression } from '~/lib/utils/color_utils';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';

const colorExpressionTypes = ['#', 'hsl', 'rgb'];

const isValidColor = (color) => {
  if (!colorExpressionTypes.some((type) => color.toLowerCase().startsWith(type))) {
    return false;
  }

  return isValidColorExpression(color);
};

const highlightColors = (doc) => {
  const decorations = [];

  doc.descendants((node, position) => {
    const { text, marks } = node;

    if (!text || marks.length === 0 || marks[0].type.name !== 'code' || !isValidColor(text)) {
      return;
    }

    const from = position;
    const to = from + text.length;
    const decoration = Decoration.inline(from, to, {
      class: 'gl-inline-flex gl-items-center content-editor-color-chip',
      style: `--gl-color-chip-color: ${text}`,
    });

    decorations.push(decoration);
  });

  return DecorationSet.create(doc, decorations);
};

export const colorDecoratorPlugin = new Plugin({
  key: new PluginKey('colorDecorator'),
  state: {
    init(_, { doc }) {
      return highlightColors(doc);
    },
    apply(transaction, oldState) {
      return transaction.docChanged ? highlightColors(transaction.doc) : oldState;
    },
  },
  props: {
    decorations(state) {
      return this.getState(state);
    },
  },
});

export default Node.create({
  name: 'colorChip',

  parseHTML() {
    return [
      {
        tag: '.gfm-color_chip',
        ignore: true,
        priority: PARSE_HTML_PRIORITY_HIGHEST,
      },
    ];
  },

  addProseMirrorPlugins() {
    return [colorDecoratorPlugin];
  },
});
