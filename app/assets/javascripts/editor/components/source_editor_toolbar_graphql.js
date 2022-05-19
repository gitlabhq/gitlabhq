import produce from 'immer';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import typeDefs from '~/editor/graphql/typedefs.graphql';
import getToolbarItemsQuery from '~/editor/graphql/get_items.query.graphql';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

const resolvers = {
  Mutation: {
    addToolbarItems: (_, { items = [] }, { cache }) => {
      const itemsSourceData = cache.readQuery({ query: getToolbarItemsQuery });
      const data = produce(itemsSourceData, (draftData) => {
        const existingNodes = draftData?.items?.nodes || [];
        draftData.items = {
          nodes: Array.isArray(items) ? [...existingNodes, ...items] : [...existingNodes, items],
        };
      });
      cache.writeQuery({ query: getToolbarItemsQuery, data });
    },

    removeToolbarItems: (_, { ids }, { cache }) => {
      const sourceData = cache.readQuery({ query: getToolbarItemsQuery });
      const {
        items: { nodes },
      } = sourceData;
      const data = produce(sourceData, (draftData) => {
        draftData.items.nodes = nodes.filter((item) => !ids.includes(item.id));
      });
      cache.writeQuery({ query: getToolbarItemsQuery, data });
    },

    updateToolbarItem: (_, { id, propsToUpdate }, { cache }) => {
      const itemSourceData = cache.readQuery({ query: getToolbarItemsQuery });
      const data = produce(itemSourceData, (draftData) => {
        const existingNodes = draftData?.items?.nodes || [];
        draftData.items = {
          nodes: existingNodes.map((item) => {
            return item.id === id ? { ...item, ...propsToUpdate } : item;
          }),
        };
      });
      cache.writeQuery({ query: getToolbarItemsQuery, data });
    },
  },
};

const defaultClient = createDefaultClient(resolvers, { typeDefs });

export const apolloProvider = new VueApollo({
  defaultClient,
});
