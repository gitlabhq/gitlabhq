import { apolloProvider } from '~/editor/components/source_editor_toolbar_graphql';
import getToolbarItemsQuery from '~/editor/graphql/get_items.query.graphql';

export const buildButton = (id = 'foo-bar-btn', options = {}) => {
  return {
    __typename: 'Item',
    id,
    label: options.label || 'Foo Bar Button',
    icon: options.icon || 'check',
    selected: options.selected || false,
    group: options.group,
    onClick: options.onClick || (() => {}),
    category: options.category || 'primary',
    selectedLabel: options.selectedLabel || 'smth',
  };
};

export const warmUpCacheWithItems = (items = []) => {
  apolloProvider.defaultClient.cache.writeQuery({
    query: getToolbarItemsQuery,
    data: {
      items: {
        nodes: items,
      },
    },
  });
};
