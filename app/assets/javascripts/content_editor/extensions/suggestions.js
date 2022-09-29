import { Node } from '@tiptap/core';
import { VueRenderer } from '@tiptap/vue-2';
import tippy from 'tippy.js';
import Suggestion from '@tiptap/suggestion';
import { PluginKey } from 'prosemirror-state';
import { isFunction } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import Reference from '../components/reference_dropdown.vue';

function createSuggestionPlugin({ editor, char, dataSource, search, referenceProps }) {
  return Suggestion({
    editor,
    char,
    pluginKey: new PluginKey(`reference_${referenceProps.referenceType}`),
    command: ({ editor: tiptapEditor, range, props }) => {
      tiptapEditor
        .chain()
        .focus()
        .insertContentAt(range, [{ type: 'reference', attrs: props }])
        .run();
    },

    async items({ query }) {
      if (!dataSource) return [];

      try {
        const items = await (isFunction(dataSource) ? dataSource() : axios.get(dataSource));
        return items.data.filter(search(query));
      } catch {
        return [];
      }
    },

    render: () => {
      let component;
      let popup;

      return {
        onStart: (props) => {
          component = new VueRenderer(Reference, {
            propsData: {
              ...props,
              char,
              referenceProps,
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
        referenceProps: {
          className: 'gfm gfm-project_member',
          referenceType: 'user',
        },
        search: (query) => ({ name, username }) =>
          name.toLocaleLowerCase().includes(query.toLocaleLowerCase()) ||
          username.toLocaleLowerCase().includes(query.toLocaleLowerCase()),
      }),
      createSuggestionPlugin({
        editor: this.editor,
        char: '#',
        dataSource: gl.GfmAutoComplete?.dataSources.issues,
        referenceProps: {
          className: 'gfm gfm-issue',
          referenceType: 'issue',
        },
        search: (query) => ({ iid, title }) =>
          String(iid).toLocaleLowerCase().includes(query.toLocaleLowerCase()) ||
          title.toLocaleLowerCase().includes(query.toLocaleLowerCase()),
      }),
      createSuggestionPlugin({
        editor: this.editor,
        char: '!',
        dataSource: gl.GfmAutoComplete?.dataSources.mergeRequests,
        referenceProps: {
          className: 'gfm gfm-issue',
          referenceType: 'merge_request',
        },
        search: (query) => ({ iid, title }) =>
          String(iid).toLocaleLowerCase().includes(query.toLocaleLowerCase()) ||
          title.toLocaleLowerCase().includes(query.toLocaleLowerCase()),
      }),
      createSuggestionPlugin({
        editor: this.editor,
        char: '%',
        dataSource: gl.GfmAutoComplete?.dataSources.milestones,
        referenceProps: {
          className: 'gfm gfm-milestone',
          referenceType: 'milestone',
        },
        search: (query) => ({ iid, title }) =>
          String(iid).toLocaleLowerCase().includes(query.toLocaleLowerCase()) ||
          title.toLocaleLowerCase().includes(query.toLocaleLowerCase()),
      }),
    ];
  },
});
