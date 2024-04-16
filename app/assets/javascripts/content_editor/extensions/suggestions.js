import { Node } from '@tiptap/core';
import { VueRenderer } from '@tiptap/vue-2';
import tippy from 'tippy.js';
import Suggestion from '@tiptap/suggestion';
import { PluginKey } from '@tiptap/pm/state';
import { uniqueId } from 'lodash';
import SuggestionsDropdown from '../components/suggestions_dropdown.vue';

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
}) {
  return Suggestion({
    editor,
    char,
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

      tiptapEditor.chain().focus().insertContentAt(range, content).run();
    },

    async items({ query, editor: tiptapEditor }) {
      const slice = tiptapEditor.state.doc.slice(0, tiptapEditor.state.selection.to);
      const markdownLine = serializer.serialize({ doc: slice.content }).split('\n').pop();

      return autocompleteHelper
        .getDataSource(referenceType, {
          command: markdownLine.match(/\/\w+/)?.[0],
          cache,
          limit,
        })
        .search(query);
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
      createPlugin('@', 'reference', 'user', { limit: 10 }),
      createPlugin('#', 'reference', 'issue'),
      createPlugin('$', 'reference', 'snippet'),
      createPlugin('~', 'referenceLabel', 'label', { limit: 20 }),
      createPlugin('&', 'reference', 'epic'),
      createPlugin('!', 'reference', 'merge_request'),
      createPlugin('[vulnerability:', 'reference', 'vulnerability'),
      createPlugin('%', 'reference', 'milestone'),
      createPlugin(':', 'emoji', 'emoji'),
      createPlugin('[[', 'link', 'wiki'),
      createPlugin('/', 'reference', 'command', {
        cache: false,
        limit: 100,
        insertionMap: {
          '/label': '~',
          '/unlabel': '~',
          '/relabel': '~',
          '/assign': '@',
          '/unassign': '@',
          '/reassign': '@',
          '/cc': '@',
          '/assign_reviewer': '@',
          '/unassign_reviewer': '@',
          '/reassign_reviewer': '@',
          '/milestone': '%',
        },
      }),
    ];
  },
});
