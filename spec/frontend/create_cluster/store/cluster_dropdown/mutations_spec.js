import {
  REQUEST_ITEMS,
  RECEIVE_ITEMS_SUCCESS,
  RECEIVE_ITEMS_ERROR,
} from '~/create_cluster/store/cluster_dropdown/mutation_types';
import createState from '~/create_cluster/store/cluster_dropdown/state';
import mutations from '~/create_cluster/store/cluster_dropdown/mutations';

describe('Cluster dropdown store mutations', () => {
  let state;
  let emptyPayload;
  let items;
  let error;

  beforeEach(() => {
    emptyPayload = {};
    items = [{ name: 'item 1' }];
    error = new Error('could not load error');
    state = createState();
  });

  it.each`
    mutation                 | mutatedProperty        | payload         | expectedValue | expectedValueDescription
    ${REQUEST_ITEMS}         | ${'isLoadingItems'}    | ${emptyPayload} | ${true}       | ${true}
    ${REQUEST_ITEMS}         | ${'loadingItemsError'} | ${emptyPayload} | ${null}       | ${null}
    ${RECEIVE_ITEMS_SUCCESS} | ${'isLoadingItems'}    | ${{ items }}    | ${false}      | ${false}
    ${RECEIVE_ITEMS_SUCCESS} | ${'items'}             | ${{ items }}    | ${items}      | ${'items payload'}
    ${RECEIVE_ITEMS_ERROR}   | ${'isLoadingItems'}    | ${{ error }}    | ${false}      | ${false}
    ${RECEIVE_ITEMS_ERROR}   | ${'error'}             | ${{ error }}    | ${error}      | ${'received error object'}
  `(`$mutation sets $mutatedProperty to $expectedValueDescription`, data => {
    const { mutation, mutatedProperty, payload, expectedValue } = data;

    mutations[mutation](state, payload);
    expect(state[mutatedProperty]).toBe(expectedValue);
  });
});
