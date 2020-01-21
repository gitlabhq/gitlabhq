import testAction from 'helpers/vuex_action_helper';

import createState from '~/create_cluster/store/cluster_dropdown/state';
import * as types from '~/create_cluster/store/cluster_dropdown/mutation_types';
import actionsFactory from '~/create_cluster/store/cluster_dropdown/actions';

describe('Cluster dropdown Store Actions', () => {
  const items = [{ name: 'item 1' }];
  let fetchFn;
  let actions;

  beforeEach(() => {
    fetchFn = jest.fn();
    actions = actionsFactory(fetchFn);
  });

  describe('fetchItems', () => {
    describe('on success', () => {
      beforeEach(() => {
        fetchFn.mockResolvedValueOnce(items);
        actions = actionsFactory(fetchFn);
      });

      it('dispatches success with received items', () =>
        testAction(
          actions.fetchItems,
          null,
          createState(),
          [],
          [
            { type: 'requestItems' },
            {
              type: 'receiveItemsSuccess',
              payload: { items },
            },
          ],
        ));
    });

    describe('on failure', () => {
      const error = new Error('Could not fetch items');

      beforeEach(() => {
        fetchFn.mockRejectedValueOnce(error);
      });

      it('dispatches success with received items', () =>
        testAction(
          actions.fetchItems,
          null,
          createState(),
          [],
          [
            { type: 'requestItems' },
            {
              type: 'receiveItemsError',
              payload: { error },
            },
          ],
        ));
    });
  });

  describe('requestItems', () => {
    it(`commits ${types.REQUEST_ITEMS} mutation`, () =>
      testAction(actions.requestItems, null, createState(), [{ type: types.REQUEST_ITEMS }]));
  });

  describe('receiveItemsSuccess', () => {
    it(`commits ${types.RECEIVE_ITEMS_SUCCESS} mutation`, () =>
      testAction(actions.receiveItemsSuccess, { items }, createState(), [
        {
          type: types.RECEIVE_ITEMS_SUCCESS,
          payload: {
            items,
          },
        },
      ]));
  });

  describe('receiveItemsError', () => {
    it(`commits ${types.RECEIVE_ITEMS_ERROR} mutation`, () => {
      const error = new Error('Error fetching items');

      testAction(actions.receiveItemsError, { error }, createState(), [
        {
          type: types.RECEIVE_ITEMS_ERROR,
          payload: {
            error,
          },
        },
      ]);
    });
  });
});
