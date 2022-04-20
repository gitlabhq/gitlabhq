import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/frequent_items/store/actions';
import * as types from '~/frequent_items/store/mutation_types';
import state from '~/frequent_items/store/state';
import AccessorUtilities from '~/lib/utils/accessor';
import axios from '~/lib/utils/axios_utils';
import {
  mockNamespace,
  mockStorageKey,
  mockFrequentProjects,
  mockSearchedProjects,
} from '../mock_data';

describe('Frequent Items Dropdown Store Actions', () => {
  let mockedState;
  let mock;

  beforeEach(() => {
    mockedState = state();
    mock = new MockAdapter(axios);

    mockedState.namespace = mockNamespace;
    mockedState.storageKey = mockStorageKey;
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setNamespace', () => {
    it('should set namespace', () => {
      return testAction(
        actions.setNamespace,
        mockNamespace,
        mockedState,
        [{ type: types.SET_NAMESPACE, payload: mockNamespace }],
        [],
      );
    });
  });

  describe('setStorageKey', () => {
    it('should set storage key', () => {
      return testAction(
        actions.setStorageKey,
        mockStorageKey,
        mockedState,
        [{ type: types.SET_STORAGE_KEY, payload: mockStorageKey }],
        [],
      );
    });
  });

  describe('requestFrequentItems', () => {
    it('should request frequent items', () => {
      return testAction(
        actions.requestFrequentItems,
        null,
        mockedState,
        [{ type: types.REQUEST_FREQUENT_ITEMS }],
        [],
      );
    });
  });

  describe('receiveFrequentItemsSuccess', () => {
    it('should set frequent items', () => {
      return testAction(
        actions.receiveFrequentItemsSuccess,
        mockFrequentProjects,
        mockedState,
        [{ type: types.RECEIVE_FREQUENT_ITEMS_SUCCESS, payload: mockFrequentProjects }],
        [],
      );
    });
  });

  describe('receiveFrequentItemsError', () => {
    it('should set frequent items error state', () => {
      return testAction(
        actions.receiveFrequentItemsError,
        null,
        mockedState,
        [{ type: types.RECEIVE_FREQUENT_ITEMS_ERROR }],
        [],
      );
    });
  });

  describe('fetchFrequentItems', () => {
    it('should dispatch `receiveFrequentItemsSuccess`', () => {
      mockedState.namespace = mockNamespace;
      mockedState.storageKey = mockStorageKey;

      return testAction(
        actions.fetchFrequentItems,
        null,
        mockedState,
        [],
        [{ type: 'requestFrequentItems' }, { type: 'receiveFrequentItemsSuccess', payload: [] }],
      );
    });

    it('should dispatch `receiveFrequentItemsError`', () => {
      jest.spyOn(AccessorUtilities, 'canUseLocalStorage').mockReturnValue(false);
      mockedState.namespace = mockNamespace;
      mockedState.storageKey = mockStorageKey;

      return testAction(
        actions.fetchFrequentItems,
        null,
        mockedState,
        [],
        [{ type: 'requestFrequentItems' }, { type: 'receiveFrequentItemsError' }],
      );
    });
  });

  describe('requestSearchedItems', () => {
    it('should request searched items', () => {
      return testAction(
        actions.requestSearchedItems,
        null,
        mockedState,
        [{ type: types.REQUEST_SEARCHED_ITEMS }],
        [],
      );
    });
  });

  describe('receiveSearchedItemsSuccess', () => {
    it('should set searched items', () => {
      return testAction(
        actions.receiveSearchedItemsSuccess,
        mockSearchedProjects,
        mockedState,
        [{ type: types.RECEIVE_SEARCHED_ITEMS_SUCCESS, payload: mockSearchedProjects }],
        [],
      );
    });
  });

  describe('receiveSearchedItemsError', () => {
    it('should set searched items error state', () => {
      return testAction(
        actions.receiveSearchedItemsError,
        null,
        mockedState,
        [{ type: types.RECEIVE_SEARCHED_ITEMS_ERROR }],
        [],
      );
    });
  });

  describe('fetchSearchedItems', () => {
    beforeEach(() => {
      gon.api_version = 'v4';
    });

    it('should dispatch `receiveSearchedItemsSuccess`', () => {
      mock.onGet(/\/api\/v4\/projects.json(.*)$/).replyOnce(200, mockSearchedProjects, {});

      return testAction(
        actions.fetchSearchedItems,
        null,
        mockedState,
        [],
        [
          { type: 'requestSearchedItems' },
          {
            type: 'receiveSearchedItemsSuccess',
            payload: { data: mockSearchedProjects, headers: {} },
          },
        ],
      );
    });

    it('should dispatch `receiveSearchedItemsError`', () => {
      gon.api_version = 'v4';
      mock.onGet(/\/api\/v4\/projects.json(.*)$/).replyOnce(500);

      return testAction(
        actions.fetchSearchedItems,
        null,
        mockedState,
        [],
        [{ type: 'requestSearchedItems' }, { type: 'receiveSearchedItemsError' }],
      );
    });
  });

  describe('setSearchQuery', () => {
    it('should commit query and dispatch `fetchSearchedItems` when query is present', () => {
      return testAction(
        actions.setSearchQuery,
        { query: 'test' },
        mockedState,
        [{ type: types.SET_SEARCH_QUERY, payload: { query: 'test' } }],
        [{ type: 'fetchSearchedItems', payload: { query: 'test' } }],
      );
    });

    it('should commit query and dispatch `fetchFrequentItems` when query is empty', () => {
      return testAction(
        actions.setSearchQuery,
        null,
        mockedState,
        [{ type: types.SET_SEARCH_QUERY, payload: null }],
        [{ type: 'fetchFrequentItems' }],
      );
    });
  });
});
