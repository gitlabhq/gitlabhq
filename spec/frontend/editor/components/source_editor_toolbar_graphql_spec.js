import { apolloProvider } from '~/editor/components/source_editor_toolbar_graphql';
import getToolbarItemsQuery from '~/editor/graphql/get_items.query.graphql';
import removeItemsMutation from '~/editor/graphql/remove_items.mutation.graphql';
import updateToolbarItemMutation from '~/editor/graphql/update_item.mutation.graphql';
import addToolbarItemsMutation from '~/editor/graphql/add_items.mutation.graphql';
import { buildButton, warmUpCacheWithItems } from './helpers';

describe('Source Editor toolbar Apollo client', () => {
  const item1 = buildButton('foo');
  const item2 = buildButton('bar');

  const getItems = () =>
    apolloProvider.defaultClient.cache.readQuery({ query: getToolbarItemsQuery })?.items?.nodes ||
    [];
  const getItem = (id) => {
    return getItems().find((item) => item.id === id);
  };

  afterEach(() => {
    apolloProvider.defaultClient.clearStore();
  });

  describe('Mutations', () => {
    describe('addToolbarItems', () => {
      function addButtons(items) {
        return apolloProvider.defaultClient.mutate({
          mutation: addToolbarItemsMutation,
          variables: {
            items,
          },
        });
      }
      it.each`
        cache      | idsToAdd                | itemsToAdd        | expectedResult    | comment
        ${[]}      | ${'empty array'}        | ${[]}             | ${[]}             | ${''}
        ${[]}      | ${'undefined'}          | ${undefined}      | ${[]}             | ${''}
        ${[]}      | ${item2.id}             | ${[item2]}        | ${[item2]}        | ${''}
        ${[]}      | ${item1.id}             | ${[item1]}        | ${[item1]}        | ${''}
        ${[]}      | ${[item1.id, item2.id]} | ${[item1, item2]} | ${[item1, item2]} | ${''}
        ${[]}      | ${[item1.id]}           | ${item1}          | ${[item1]}        | ${'does not fail if the item is an Object'}
        ${[item2]} | ${[item1.id]}           | ${item1}          | ${[item2, item1]} | ${'does not fail if the item is an Object'}
        ${[item1]} | ${[item2.id]}           | ${[item2]}        | ${[item1, item2]} | ${'correctly adds items to the pre-populated cache'}
      `('adds $idsToAdd item(s) to $cache', async ({ cache, itemsToAdd, expectedResult }) => {
        await warmUpCacheWithItems(cache);
        await addButtons(itemsToAdd);
        await expect(getItems()).toEqual(expectedResult);
      });
    });

    describe('removeToolbarItems', () => {
      function removeButtons(ids) {
        return apolloProvider.defaultClient.mutate({
          mutation: removeItemsMutation,
          variables: {
            ids,
          },
        });
      }

      it.each`
        cache             | cacheIds                | toRemove                | expected
        ${[item1, item2]} | ${[item1.id, item2.id]} | ${[item1.id]}           | ${[item2]}
        ${[item1, item2]} | ${[item1.id, item2.id]} | ${[item2.id]}           | ${[item1]}
        ${[item1, item2]} | ${[item1.id, item2.id]} | ${[item1.id, item2.id]} | ${[]}
        ${[item1]}        | ${[item1.id]}           | ${[item1.id]}           | ${[]}
        ${[item2]}        | ${[item2.id]}           | ${[]}                   | ${[item2]}
        ${[]}             | ${['undefined']}        | ${[item1.id]}           | ${[]}
        ${[item1]}        | ${[item1.id]}           | ${[item2.id]}           | ${[item1]}
      `('removes $toRemove from the $cacheIds toolbar', async ({ cache, toRemove, expected }) => {
        await warmUpCacheWithItems(cache);

        expect(getItems()).toHaveLength(cache.length);

        await removeButtons(toRemove);

        expect(getItems()).toHaveLength(expected.length);
        expect(getItems()).toEqual(expected);
      });
    });

    describe('updateToolbarItem', () => {
      function mutateButton(item, propsToUpdate = {}) {
        return apolloProvider.defaultClient.mutate({
          mutation: updateToolbarItemMutation,
          variables: {
            id: item.id,
            propsToUpdate,
          },
        });
      }

      beforeEach(() => {
        warmUpCacheWithItems([item1, item2]);
      });

      it('updates the toolbar items', async () => {
        expect(getItem(item1.id).selected).toBe(false);
        expect(getItem(item2.id).selected).toBe(false);

        await mutateButton(item1, { selected: true });

        expect(getItem(item1.id).selected).toBe(true);
        expect(getItem(item2.id).selected).toBe(false);

        await mutateButton(item2, { selected: true });

        expect(getItem(item1.id).selected).toBe(true);
        expect(getItem(item2.id).selected).toBe(true);
      });
    });
  });
});
