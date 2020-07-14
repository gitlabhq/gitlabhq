import RecentSearchesStore from '~/filtered_search/stores/recent_searches_store';

describe('RecentSearchesStore', () => {
  let store;

  beforeEach(() => {
    store = new RecentSearchesStore();
  });

  describe('addRecentSearch', () => {
    it('should add to the front of the list', () => {
      store.addRecentSearch('foo');
      store.addRecentSearch('bar');

      expect(store.state.recentSearches).toEqual(['bar', 'foo']);
    });

    it('should deduplicate', () => {
      store.addRecentSearch('foo');
      store.addRecentSearch('bar');
      store.addRecentSearch('foo');

      expect(store.state.recentSearches).toEqual(['foo', 'bar']);
    });

    it('only keeps track of 5 items', () => {
      store.addRecentSearch('1');
      store.addRecentSearch('2');
      store.addRecentSearch('3');
      store.addRecentSearch('4');
      store.addRecentSearch('5');
      store.addRecentSearch('6');
      store.addRecentSearch('7');

      expect(store.state.recentSearches).toEqual(['7', '6', '5', '4', '3']);
    });
  });

  describe('setRecentSearches', () => {
    it('should override list', () => {
      store.setRecentSearches(['foo', 'bar']);
      store.setRecentSearches(['baz', 'qux']);

      expect(store.state.recentSearches).toEqual(['baz', 'qux']);
    });

    it('handles non-string values', () => {
      store.setRecentSearches(['foo  ', { foo: 'bar' }, { foo: 'bar' }, ['foobar']]);

      // 1. String values will be trimmed of leading/trailing spaces
      // 2. Comparison will account for objects to remove duplicates
      // 3. Old behaviour of handling string values stays as it is.
      expect(store.state.recentSearches).toEqual(['foo', { foo: 'bar' }, ['foobar']]);
    });

    it('only keeps track of 5 items', () => {
      store.setRecentSearches(['1', '2', '3', '4', '5', '6', '7']);

      expect(store.state.recentSearches).toEqual(['1', '2', '3', '4', '5']);
    });
  });
});
