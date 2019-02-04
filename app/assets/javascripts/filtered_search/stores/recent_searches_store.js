import _ from 'underscore';

class RecentSearchesStore {
  constructor(initialState = {}, allowedKeys) {
    this.state = Object.assign(
      {
        isLocalStorageAvailable: true,
        recentSearches: [],
        allowedKeys,
      },
      initialState,
    );
  }

  addRecentSearch(newSearch) {
    this.setRecentSearches([newSearch].concat(this.state.recentSearches));

    return this.state.recentSearches;
  }

  setRecentSearches(searches = []) {
    const trimmedSearches = searches.map(search => search.trim());
    this.state.recentSearches = _.uniq(trimmedSearches).slice(0, 5);
    return this.state.recentSearches;
  }
}

export default RecentSearchesStore;
