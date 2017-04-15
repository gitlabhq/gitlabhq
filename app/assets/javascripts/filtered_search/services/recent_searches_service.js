class RecentSearchesService {
  constructor(localStorageKey = 'issuable-recent-searches') {
    this.localStorageKey = localStorageKey;
  }

  fetch() {
    const input = window.localStorage.getItem(this.localStorageKey);

    let searches = [];
    if (input && input.length > 0) {
      try {
        searches = JSON.parse(input);
      } catch (err) {
        return Promise.reject(err);
      }
    }

    return Promise.resolve(searches);
  }

  save(searches = []) {
    window.localStorage.setItem(this.localStorageKey, JSON.stringify(searches));
  }
}

export default RecentSearchesService;
