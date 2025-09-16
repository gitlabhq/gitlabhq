import { Node } from '@tiptap/core';
import { VueRenderer } from '@tiptap/vue-2';
import tippy from 'tippy.js';
import Suggestion from '@tiptap/suggestion';
import { PluginKey } from '@tiptap/pm/state';
import { uniqueId } from 'lodash';
import { REFERENCE_TYPES } from '~/content_editor/constants/reference_types';
import {
  prioritizeCommandsWithFrequent,
  recordFrequentCommandUsage,
} from '~/editor/quick_action_suggestions';
import SuggestionsDropdown from '../components/suggestions_dropdown.vue';
import { COMMANDS } from '../constants';
import CodeBlockHighlight from './code_block_highlight';
import Diagram from './diagram';
import Frontmatter from './frontmatter';
import Code from './code';

const CODE_NODE_TYPES = [CodeBlockHighlight.name, Diagram.name, Frontmatter.name, Code.name];

function expandRangeToIncludeText(range, text, tiptapEditor) {
  if (!text) return range;

  const { state } = tiptapEditor;
  const { from, to: originalTo } = range;
  const maxTo = Math.min(from + text.length, state.doc.content.size);
  const docSliceText = state.doc.textBetween(from, maxTo, '\n', '\uFFFC');
  let matchedLen = 0;
  for (; matchedLen < docSliceText.length; matchedLen += 1) {
    if (docSliceText[matchedLen] !== text[matchedLen]) break;
  }
  const expandedTo = Math.max(originalTo, from + matchedLen);
  return { from, to: expandedTo };
}

function createSuggestionPlugin({
  editor,
  char,
  limit = 5,
  nodeType,
  referenceType,
  cache = true,
  insertionMap = {},
  serializer,
  autocompleteHelper,
  ...options
}) {
  return Suggestion({
    editor,
    char,
    allowSpaces: true,
    pluginKey: new PluginKey(uniqueId('suggestions')),

    command: ({ editor: tiptapEditor, range, props }) => {
      let content;

      if (nodeType === 'link') {
        content = [
          {
            type: 'text',
            text: props.text,
            marks: [{ type: 'link', attrs: props }],
          },
        ];
      } else {
        content = [
          { type: nodeType, attrs: props },
          { type: 'text', text: ` ${insertionMap[props.text] || ''}` },
        ];
      }

      // Record frequent command usage for slash-commands
      if (char === '/') {
        const name = props?.name || props?.text;
        if (typeof name === 'string' && name.length > 0) {
          recordFrequentCommandUsage(name);
        }
      }

      // Try to expand the range forward to include as much of props.text as possible
      const expandedRange = expandRangeToIncludeText(range, props.text, tiptapEditor);
      tiptapEditor.chain().focus().insertContentAt(expandedRange, content).run();
    },

    async items({ query, editor: tiptapEditor }) {
      if (CODE_NODE_TYPES.some((type) => tiptapEditor.isActive(type))) return [];
      const slice = tiptapEditor.state.doc.slice(0, tiptapEditor.state.selection.to);
      const markdownLine = serializer.serialize({ doc: slice.content }).split('\n').pop();

      return autocompleteHelper
        .getDataSource(referenceType, {
          command: markdownLine.match(/\/\w+/)?.[0],
          cache,
          limit,
          ...options,
        })
        .search(query)
        .then((data) => {
          if (!query) {
            return prioritizeCommandsWithFrequent(data);
          }

          return data;
        });
    },

    render: () => {
      let component;
      let popup;
      let isHidden = false;

      const onUpdate = (props) => {
        component?.updateProps({ ...props, loading: false });

        if (!props.clientRect) return;

        popup?.[0].setProps({
          getReferenceClientRect: props.clientRect,
        });
      };

      return {
        onBeforeStart: (props) => {
          component = new VueRenderer(SuggestionsDropdown, {
            propsData: {
              ...props,
              char,
              nodeType,
              nodeProps: { referenceType },
              loading: true,
            },
            editor: props.editor,
          });

          if (!props.clientRect) {
            return;
          }

          popup = tippy('body', {
            getReferenceClientRect: props.clientRect,
            appendTo: () => document.body,
            onHide: () => {
              isHidden = true;
            },
            onShow: () => {
              isHidden = false;
            },
            content: component.element,
            showOnCreate: true,
            interactive: true,
            trigger: 'manual',
            placement: 'bottom-start',
          });
        },

        onStart: onUpdate,
        onUpdate,

        onKeyDown(props) {
          if (isHidden) return false;

          if (props.event.key === 'Escape') {
            popup?.[0].hide();

            return true;
          }

          return component?.ref?.onKeyDown(props);
        },

        onExit() {
          popup?.[0].destroy();
          component?.destroy();
        },
      };
    },
    ...options,
  });
}

export default Node.create({
  name: 'suggestions',

  addOptions() {
    return {
      autocompleteHelper: {},
      serializer: null,
    };
  },

  addProseMirrorPlugins() {
    const { serializer, autocompleteHelper } = this.options;

    // eslint-disable-next-line max-params
    const createPlugin = (char, nodeType, referenceType, options = {}) =>
      createSuggestionPlugin({
        editor: this.editor,
        char,
        nodeType,
        referenceType,
        serializer,
        autocompleteHelper,
        ...options,
      });

    return [
      createPlugin('@', 'reference', REFERENCE_TYPES.USER, { limit: 10, filterOnBackend: true }),
      createPlugin('#', 'reference', REFERENCE_TYPES.ISSUE, { filterOnBackend: true }),
      createPlugin('[issue:', 'reference', REFERENCE_TYPES.ISSUE_ALTERNATIVE, {
        filterOnBackend: true,
      }),
      createPlugin('[work_item:', 'reference', REFERENCE_TYPES.WORK_ITEM, {
        filterOnBackend: true,
      }),
      createPlugin('$', 'reference', REFERENCE_TYPES.SNIPPET),
      createPlugin('~', 'referenceLabel', REFERENCE_TYPES.LABEL, { limit: 100 }),
      createPlugin('&', 'reference', REFERENCE_TYPES.EPIC),
      createPlugin('[epic:', 'reference', REFERENCE_TYPES.EPIC_ALTERNATIVE),
      createPlugin('!', 'reference', REFERENCE_TYPES.MERGE_REQUEST),
      createPlugin('[vulnerability:', 'reference', REFERENCE_TYPES.VULNERABILITY, {
        filterOnBackend: true,
      }),
      createPlugin('*iteration:', 'reference', REFERENCE_TYPES.ITERATION),
      createPlugin('"', 'reference', REFERENCE_TYPES.STATUS, { limit: 100 }),
      createPlugin('%', 'reference', REFERENCE_TYPES.MILESTONE),
      createPlugin(':', 'emoji', REFERENCE_TYPES.EMOJI),
      createPlugin('[[', 'link', REFERENCE_TYPES.WIKI),
      createPlugin('/', 'reference', REFERENCE_TYPES.COMMAND, {
        cache: false,
        limit: 100,
        startOfLine: true,
        insertionMap: {
          [COMMANDS.LABEL]: '~',
          [COMMANDS.UNLABEL]: '~',
          [COMMANDS.RELABEL]: '~',
          [COMMANDS.ASSIGN]: '@',
          [COMMANDS.UNASSIGN]: '@',
          [COMMANDS.REASSIGN]: '@',
          [COMMANDS.ASSIGN_REVIEWER]: '@',
          [COMMANDS.UNASSIGN_REVIEWER]: '@',
          [COMMANDS.REASSIGN_REVIEWER]: '@',
          [COMMANDS.MILESTONE]: '%',
          [COMMANDS.ITERATION]: '*iteration:',
          [COMMANDS.STATUS]: '"',
        },
      }),
    ];
  },
});
