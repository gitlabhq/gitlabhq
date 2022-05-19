import Vue from 'vue';
import getToolbarItemsQuery from '~/editor/graphql/get_items.query.graphql';
import removeToolbarItemsMutation from '~/editor/graphql/remove_items.mutation.graphql';
import updateToolbarItemMutation from '~/editor/graphql/update_item.mutation.graphql';
import addToolbarItemsMutation from '~/editor/graphql/add_items.mutation.graphql';
import SourceEditorToolbar from '~/editor/components/source_editor_toolbar.vue';
import { apolloProvider } from '~/editor/components/source_editor_toolbar_graphql';

const client = apolloProvider.defaultClient;

export class ToolbarExtension {
  /**
   * A required getter returning the extension's name
   * We have to provide it for every extension instead of relying on the built-in
   * `name` prop because the prop does not survive the webpack's minification
   * and the name mangling.
   * @returns {string}
   */
  static get extensionName() {
    return 'ToolbarExtension';
  }
  /**
   * THE LIFE-CYCLE CALLBACKS
   */

  /**
   * Is called before the extension gets used by an instance,
   * Use `onSetup` to setup Monaco directly:
   * actions, keystrokes, update options, etc.
   * Is called only once before the extension gets registered
   *
   * @param { Object } [instance] The Source Editor instance
   * @param { Object } [setupOptions]  The setupOptions object
   */
  // eslint-disable-next-line class-methods-use-this
  onSetup(instance, setupOptions) {
    const el = setupOptions?.el || document.getElementById('editor-toolbar');
    ToolbarExtension.setupVue(el);
  }

  static setupVue(el) {
    client.cache.writeQuery({ query: getToolbarItemsQuery, data: { items: { nodes: [] } } });
    const ToolbarComponent = Vue.extend(SourceEditorToolbar);

    const toolbar = new ToolbarComponent({
      el,
      apolloProvider,
    });
    toolbar.$mount();
  }

  /**
   * The public API of the extension: these are the methods that will be exposed
   * to the end user
   * @returns {Object}
   */
  // eslint-disable-next-line class-methods-use-this
  provides() {
    return {
      toolbar: {
        getItem: (id) => {
          const items = client.readQuery({ query: getToolbarItemsQuery })?.items?.nodes || [];
          return items.find((item) => item.id === id);
        },
        getAllItems: () => {
          return client.readQuery({ query: getToolbarItemsQuery })?.items?.nodes || [];
        },
        addItems: (items = []) => {
          return client.mutate({
            mutation: addToolbarItemsMutation,
            variables: {
              items,
            },
          });
        },
        removeItems: (ids = []) => {
          client.mutate({
            mutation: removeToolbarItemsMutation,
            variables: {
              ids,
            },
          });
        },
        updateItem: (id = '', propsToUpdate = {}) => {
          if (id) {
            client.mutate({
              mutation: updateToolbarItemMutation,
              variables: {
                id,
                propsToUpdate,
              },
            });
          }
        },
      },
    };
  }
}
