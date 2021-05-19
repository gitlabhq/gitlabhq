import { transformBoardConfig } from 'ee_else_ce/boards/boards_util';
import FilteredSearchManager from 'ee_else_ce/filtered_search/filtered_search_manager';
import IssuableFilteredSearchTokenKeys from 'ee_else_ce/filtered_search/issuable_filtered_search_token_keys';
import { updateHistory } from '~/lib/utils/url_utility';
import FilteredSearchContainer from '../filtered_search/container';
import vuexstore from './stores';
import boardsStore from './stores/boards_store';

export default class FilteredSearchBoards extends FilteredSearchManager {
  constructor(store, updateUrl = false, cantEdit = []) {
    super({
      page: 'boards',
      isGroupDecendent: true,
      stateFiltersSelector: '.issues-state-filters',
      isGroup: IS_EE,
      useDefaultState: false,
      filteredSearchTokenKeys: IssuableFilteredSearchTokenKeys,
    });

    this.store = store;
    this.updateUrl = updateUrl;

    // Issue boards is slightly different, we handle all the requests async
    // instead or reloading the page, we just re-fire the list ajax requests
    this.isHandledAsync = true;
    this.cantEdit = cantEdit.filter((i) => typeof i === 'string');
    this.cantEditWithValue = cantEdit.filter((i) => typeof i === 'object');

    if (vuexstore.getters.shouldUseGraphQL && vuexstore.state.boardConfig) {
      const boardConfigPath = transformBoardConfig(vuexstore.state.boardConfig);
      // TODO Refactor: https://gitlab.com/gitlab-org/gitlab/-/issues/329274
      // here we are using "window.location.search" as a temporary store
      // only to unpack the params and do another validation inside
      // 'performSearch' and 'setFilter' vuex actions.
      if (boardConfigPath !== '') {
        const filterPath = window.location.search ? `${window.location.search}&` : '?';
        updateHistory({
          url: `${filterPath}${transformBoardConfig(vuexstore.state.boardConfig)}`,
        });
      }
    }
  }

  updateObject(path) {
    const groupByParam = new URLSearchParams(window.location.search).get('group_by');
    this.store.path = `${path.substr(1)}${groupByParam ? `&group_by=${groupByParam}` : ''}`;

    if (vuexstore.getters.shouldUseGraphQL) {
      updateHistory({
        url: `?${path.substr(1)}${groupByParam ? `&group_by=${groupByParam}` : ''}`,
      });
      vuexstore.dispatch('performSearch');
    } else if (this.updateUrl) {
      boardsStore.updateFiltersUrl();
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
    if (this.cantEdit.includes(tokenName)) return false;
    return (
      this.cantEditWithValue.findIndex(
        (token) => token.name === tokenName && token.value === tokenValue,
      ) === -1
    );
  }
}
