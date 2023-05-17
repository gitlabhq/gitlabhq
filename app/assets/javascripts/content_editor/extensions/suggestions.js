import { Node } from '@tiptap/core';
import { VueRenderer } from '@tiptap/vue-2';
import tippy from 'tippy.js';
import Suggestion from '@tiptap/suggestion';
import { PluginKey } from '@tiptap/pm/state';
import { isFunction, uniqueId, memoize } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { initEmojiMap, getAllEmoji } from '~/emoji';
import SuggestionsDropdown from '../components/suggestions_dropdown.vue';

function find(haystack, needle) {
  return String(haystack).toLocaleLowerCase().includes(String(needle).toLocaleLowerCase());
}

function createSuggestionPlugin({
  editor,
  char,
  dataSource,
  search,
  limit = 15,
  nodeType,
  nodeProps = {},
}) {
  const fetchData = memoize(
    isFunction(dataSource) ? dataSource : async () => (await axios.get(dataSource)).data,
  );

  return Suggestion({
    editor,
    char,
    pluginKey: new PluginKey(uniqueId('suggestions')),

    command: ({ editor: tiptapEditor, range, props }) => {
      tiptapEditor
        .chain()
        .focus()
        .insertContentAt(range, [
          { type: nodeType, attrs: props },
          { type: 'text', text: ' ' },
        ])
        .run();
    },

    async items({ query }) {
      if (!dataSource) return [];

      try {
        const items = await fetchData();

        return items.filter(search(query)).slice(0, limit);
      } catch {
        return [];
      }
    },

    render: () => {
      let component;
      let popup;

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
              nodeProps,
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
      autocompleteDataSources: {},
    };
  },

  addProseMirrorPlugins() {
    return [
      createSuggestionPlugin({
        editor: this.editor,
        char: '@',
        dataSource: this.options.autocompleteDataSources.members,
        nodeType: 'reference',
        nodeProps: {
          referenceType: 'user',
        },
        search: (query) => ({ name, username }) => find(name, query) || find(username, query),
      }),
      createSuggestionPlugin({
        editor: this.editor,
        char: '#',
        dataSource: this.options.autocompleteDataSources.issues,
        nodeType: 'reference',
        nodeProps: {
          referenceType: 'issue',
        },
        search: (query) => ({ iid, title }) => find(iid, query) || find(title, query),
      }),
      createSuggestionPlugin({
        editor: this.editor,
        char: '$',
        dataSource: this.options.autocompleteDataSources.snippets,
        nodeType: 'reference',
        nodeProps: {
          referenceType: 'snippet',
        },
        search: (query) => ({ id, title }) => find(id, query) || find(title, query),
      }),
      createSuggestionPlugin({
        editor: this.editor,
        char: '~',
        dataSource: this.options.autocompleteDataSources.labels,
        nodeType: 'reference_label',
        nodeProps: {
          referenceType: 'label',
        },
        search: (query) => ({ title }) => find(title, query),
      }),
      createSuggestionPlugin({
        editor: this.editor,
        char: '&',
        dataSource: this.options.autocompleteDataSources.epics,
        nodeType: 'reference',
        nodeProps: {
          referenceType: 'epic',
        },
        search: (query) => ({ iid, title }) => find(iid, query) || find(title, query),
      }),
      createSuggestionPlugin({
        editor: this.editor,
        char: '[vulnerability:',
        dataSource: this.options.autocompleteDataSources.vulnerabilities,
        nodeType: 'reference',
        nodeProps: {
          referenceType: 'vulnerability',
        },
        search: (query) => ({ id, title }) => find(id, query) || find(title, query),
      }),
      createSuggestionPlugin({
        editor: this.editor,
        char: '!',
        dataSource: this.options.autocompleteDataSources.mergeRequests,
        nodeType: 'reference',
        nodeProps: {
          referenceType: 'merge_request',
        },
        search: (query) => ({ iid, title }) => find(iid, query) || find(title, query),
      }),
      createSuggestionPlugin({
        editor: this.editor,
        char: '%',
        dataSource: this.options.autocompleteDataSources.milestones,
        nodeType: 'reference',
        nodeProps: {
          referenceType: 'milestone',
        },
        search: (query) => ({ iid, title }) => find(iid, query) || find(title, query),
      }),
      createSuggestionPlugin({
        editor: this.editor,
        char: '/',
        dataSource: this.options.autocompleteDataSources.commands,
        nodeType: 'reference',
        nodeProps: {
          referenceType: 'command',
        },
        search: (query) => ({ name }) => find(name, query),
      }),
      createSuggestionPlugin({
        editor: this.editor,
        char: ':',
        dataSource: () => Object.values(getAllEmoji()),
        nodeType: 'emoji',
        search: (query) => ({ d, name }) => find(d, query) || find(name, query),
        limit: 10,
      }),
    ];
  },

  onCreate() {
    initEmojiMap();
  },
});
