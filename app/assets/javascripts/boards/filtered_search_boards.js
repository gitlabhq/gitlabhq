/* eslint-disable class-methods-use-this */
import FilteredSearchContainer from '../filtered_search/container';

export default class FilteredSearchBoards extends gl.FilteredSearchManager {
  constructor(store, updateUrl = false, cantEdit = []) {
    super('boards');

    this.store = store;
    this.updateUrl = updateUrl;

    // Issue boards is slightly different, we handle all the requests async
    // instead or reloading the page, we just re-fire the list ajax requests
    this.isHandledAsync = true;
    this.cantEdit = cantEdit;
    this.hiddenTokenNames = cantEdit.map(i => i.tokenName);
  }

  updateObject(path) {
    this.store.path = path.substr(1);

    if (this.updateUrl) {
      gl.issueBoards.BoardsStore.updateFiltersUrl();
    }
  }

  removeTokens() {
    const tokens = FilteredSearchContainer.container.querySelectorAll('.js-visual-token');

    // Remove all the tokens as they will be replaced by the search manager
    [].forEach.call(tokens, (el) => {
      el.parentNode.removeChild(el);
    });

    this.filteredSearchInput.value = '';
  }

  updateTokens() {
    this.removeTokens();

    this.loadSearchParamsFromURL();

    // Get the placeholder back if search is empty
    this.filteredSearchInput.dispatchEvent(new Event('input'));
  }

  canEdit(tokenName, tokenValue) {
    if (tokenValue && this.hiddenTokenNames.includes(tokenName)) {
      return this.cantEdit.findIndex(i => i.tokenName === tokenName && i.value === tokenValue) === -1;
    }
    return this.hiddenTokenNames.indexOf(tokenName) === -1;
  }
}
