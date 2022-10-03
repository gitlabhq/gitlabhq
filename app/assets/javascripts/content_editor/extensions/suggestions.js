import { Node } from '@tiptap/core';
import { VueRenderer } from '@tiptap/vue-2';
import tippy from 'tippy.js';
import Suggestion from '@tiptap/suggestion';
import { PluginKey } from 'prosemirror-state';
import { isFunction, uniqueId } from 'lodash';
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
  limit = Infinity,
  nodeType,
  nodeProps = {},
}) {
  return Suggestion({
    editor,
    char,
    pluginKey: new PluginKey(uniqueId('suggestions')),

    command: ({ editor: tiptapEditor, range, props }) => {
      tiptapEditor
        .chain()
        .focus()
        .insertContentAt(range, [{ type: nodeType, attrs: props }])
        .run();
    },

    async items({ query }) {
      if (!dataSource) return [];

      try {
        const items = isFunction(dataSource)
          ? await dataSource()
          : (await axios.get(dataSource)).data;

        return items.filter(search(query)).slice(0, limit);
      } catch {
        return [];
      }
    },

    render: () => {
      let component;
      let popup;

      return {
        onStart: (props) => {
          component = new VueRenderer(SuggestionsDropdown, {
            propsData: {
              ...props,
              char,
              nodeType,
              nodeProps,
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

        onUpdate(props) {
          component.updateProps(props);

          if (!props.clientRect) {
            return;
          }

          popup?.[0].setProps({
            getReferenceClientRect: props.clientRect,
          });
        },

        onKeyDown(props) {
          if (props.event.key === 'Escape') {
            popup?.[0].hide();

            return true;
          }

          return component.ref?.onKeyDown(props);
        },

        onExit() {
          popup?.[0].destroy();
          component.destroy();
        },
      };
    },
  });
}

export default Node.create({
  name: 'suggestions',

  addProseMirrorPlugins() {
    return [
      createSuggestionPlugin({
        editor: this.editor,
        char: '@',
        dataSource: gl.GfmAutoComplete?.dataSources.members,
        nodeType: 'reference',
        nodeProps: {
          className: 'gfm gfm-project_member',
          referenceType: 'user',
        },
        search: (query) => ({ name, username }) => find(name, query) || find(username, query),
      }),
      createSuggestionPlugin({
        editor: this.editor,
        char: '#',
        dataSource: gl.GfmAutoComplete?.dataSources.issues,
        nodeType: 'reference',
        nodeProps: {
          className: 'gfm gfm-issue',
          referenceType: 'issue',
        },
        search: (query) => ({ iid, title }) => find(iid, query) || find(title, query),
      }),
      createSuggestionPlugin({
        editor: this.editor,
        char: '!',
        dataSource: gl.GfmAutoComplete?.dataSources.mergeRequests,
        nodeType: 'reference',
        nodeProps: {
          className: 'gfm gfm-issue',
          referenceType: 'merge_request',
        },
        search: (query) => ({ iid, title }) => find(iid, query) || find(title, query),
      }),
      createSuggestionPlugin({
        editor: this.editor,
        char: '%',
        dataSource: gl.GfmAutoComplete?.dataSources.milestones,
        nodeType: 'reference',
        nodeProps: {
          className: 'gfm gfm-milestone',
          referenceType: 'milestone',
        },
        search: (query) => ({ iid, title }) => find(iid, query) || find(title, query),
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
