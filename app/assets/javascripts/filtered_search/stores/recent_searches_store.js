import { uniqWith, isEqual } from 'lodash';

import { MAX_HISTORY_SIZE } from '../constants';

class RecentSearchesStore {
  constructor(initialState = {}, allowedKeys) {
    this.state = {
      isLocalStorageAvailable: true,
      recentSearches: [],
      allowedKeys,
      ...initialState,
    };
  }

  addRecentSearch(newSearch) {
    this.setRecentSearches([newSearch].concat(this.state.recentSearches));

    return this.state.recentSearches;
  }

  setRecentSearches(searches = []) {
    const trimmedSearches = searches.map((search) =>
      typeof search === 'string' ? search.trim() : search,
    );

    // Do object equality check to remove duplicates.
    this.state.recentSearches = uniqWith(trimmedSearches, isEqual).slice(0, MAX_HISTORY_SIZE);
    return this.state.recentSearches;
  }
}

export default RecentSearchesStore;
