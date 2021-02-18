import * as types from '~/frequent_items/store/mutation_types';
import mutations from '~/frequent_items/store/mutations';
import state from '~/frequent_items/store/state';
import {
  mockNamespace,
  mockStorageKey,
  mockFrequentProjects,
  mockSearchedProjects,
  mockProcessedSearchedProjects,
  mockSearchedGroups,
  mockProcessedSearchedGroups,
} from '../mock_data';

describe('Frequent Items dropdown mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state();
  });

  describe('SET_NAMESPACE', () => {
    it('should set namespace', () => {
      mutations[types.SET_NAMESPACE](stateCopy, mockNamespace);

      expect(stateCopy.namespace).toEqual(mockNamespace);
    });
  });

  describe('SET_STORAGE_KEY', () => {
    it('should set storage key', () => {
      mutations[types.SET_STORAGE_KEY](stateCopy, mockStorageKey);

      expect(stateCopy.storageKey).toEqual(mockStorageKey);
    });
  });

  describe('SET_SEARCH_QUERY', () => {
    it('should set search query', () => {
      const searchQuery = 'gitlab-ce';

      mutations[types.SET_SEARCH_QUERY](stateCopy, searchQuery);

      expect(stateCopy.searchQuery).toEqual(searchQuery);
    });
  });

  describe('REQUEST_FREQUENT_ITEMS', () => {
    it('should set view states when requesting frequent items', () => {
      mutations[types.REQUEST_FREQUENT_ITEMS](stateCopy);

      expect(stateCopy.isLoadingItems).toEqual(true);
      expect(stateCopy.hasSearchQuery).toEqual(false);
    });
  });

  describe('RECEIVE_FREQUENT_ITEMS_SUCCESS', () => {
    it('should set view states when receiving frequent items', () => {
      mutations[types.RECEIVE_FREQUENT_ITEMS_SUCCESS](stateCopy, mockFrequentProjects);

      expect(stateCopy.items).toEqual(mockFrequentProjects);
      expect(stateCopy.isLoadingItems).toEqual(false);
      expect(stateCopy.hasSearchQuery).toEqual(false);
      expect(stateCopy.isFetchFailed).toEqual(false);
    });
  });

  describe('RECEIVE_FREQUENT_ITEMS_ERROR', () => {
    it('should set items and view states when error occurs retrieving frequent items', () => {
      mutations[types.RECEIVE_FREQUENT_ITEMS_ERROR](stateCopy);

      expect(stateCopy.items).toEqual([]);
      expect(stateCopy.isLoadingItems).toEqual(false);
      expect(stateCopy.hasSearchQuery).toEqual(false);
      expect(stateCopy.isFetchFailed).toEqual(true);
    });
  });

  describe('REQUEST_SEARCHED_ITEMS', () => {
    it('should set view states when requesting searched items', () => {
      mutations[types.REQUEST_SEARCHED_ITEMS](stateCopy);

      expect(stateCopy.isLoadingItems).toEqual(true);
      expect(stateCopy.hasSearchQuery).toEqual(true);
    });
  });

  describe('RECEIVE_SEARCHED_ITEMS_SUCCESS', () => {
    it('should set items and view states when receiving searched items', () => {
      mutations[types.RECEIVE_SEARCHED_ITEMS_SUCCESS](stateCopy, mockSearchedProjects);

      expect(stateCopy.items).toEqual(mockProcessedSearchedProjects);
      expect(stateCopy.isLoadingItems).toEqual(false);
      expect(stateCopy.hasSearchQuery).toEqual(true);
      expect(stateCopy.isFetchFailed).toEqual(false);
    });

    it('should also handle the different `full_name` key for namespace in groups payload', () => {
      mutations[types.RECEIVE_SEARCHED_ITEMS_SUCCESS](stateCopy, mockSearchedGroups);

      expect(stateCopy.items).toEqual(mockProcessedSearchedGroups);
      expect(stateCopy.isLoadingItems).toEqual(false);
      expect(stateCopy.hasSearchQuery).toEqual(true);
      expect(stateCopy.isFetchFailed).toEqual(false);
    });
  });

  describe('RECEIVE_SEARCHED_ITEMS_ERROR', () => {
    it('should set view states when error occurs retrieving searched items', () => {
      mutations[types.RECEIVE_SEARCHED_ITEMS_ERROR](stateCopy);

      expect(stateCopy.items).toEqual([]);
      expect(stateCopy.isLoadingItems).toEqual(false);
      expect(stateCopy.hasSearchQuery).toEqual(true);
      expect(stateCopy.isFetchFailed).toEqual(true);
    });
  });
});
