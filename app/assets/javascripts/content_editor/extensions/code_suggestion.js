import { lowlight } from 'lowlight/lib/core';
import { Fragment } from '@tiptap/pm/model';
import { textblockTypeInputRule } from '@tiptap/core';
import { PARSE_HTML_PRIORITY_HIGHEST } from '../constants';
import CodeBlockHighlight from './code_block_highlight';

const backtickInputRegex = /^```suggestion[\s\n]$/;

export default CodeBlockHighlight.extend({
  name: 'codeSuggestion',

  isolating: true,

  addOptions() {
    return {
      lowlight,
      codeSuggestionsConfig: {},
    };
  },

  addAttributes() {
    return {
      ...this.parent?.(),
      language: {
        default: 'suggestion',
      },
      isCodeSuggestion: {
        default: true,
      },
    };
  },

  addCommands() {
    const ext = this;

    return {
      insertCodeSuggestion:
        (attributes) =>
        async ({ editor }) => {
          // do not insert a new suggestion if already inside a suggestion
          if (editor.isActive('codeSuggestion')) return false;

          const config = ext.options.codeSuggestionsConfig;

          const suggestionLines = config.lines ?? [];

          // Ensure insertContent is always dispatched asynchronously so it's
          // outside TipTap's synchronous command dispatch cycle.
          await Promise.resolve();

          const content = suggestionLines.join('\n');
          const lineNumbers = `-${Math.max(suggestionLines.length - 1, 0)}+0`;

          editor.commands.insertContent({
            type: 'codeSuggestion',
            attrs: { langParams: lineNumbers, ...attributes },
            // empty strings are not allowed in text nodes
            content: [{ type: 'text', text: content || ' ' }],
          });

          return true;
        },
    };
  },

  parseHTML() {
    return [
      {
        priority: PARSE_HTML_PRIORITY_HIGHEST,
        tag: 'pre[data-canonical-lang="suggestion"]',
        getContent(element, schema) {
          return element.textContent
            ? Fragment.from(schema.text(element.textContent))
            : Fragment.empty;
        },
      },
    ];
  },

  addInputRules() {
    return [
      textblockTypeInputRule({
        find: backtickInputRegex,
        type: this.type,
        getAttributes: () => ({ language: 'suggestion', langParams: '-0+0' }),
      }),
    ];
  },
});
