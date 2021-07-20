import { last } from 'lodash';
import recentSearchesStorageKeys from 'ee_else_ce/filtered_search/recent_searches_storage_keys';
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';
import createFlash from '~/flash';
import {
  ENTER_KEY_CODE,
  BACKSPACE_KEY_CODE,
  DELETE_KEY_CODE,
  UP_KEY_CODE,
  DOWN_KEY_CODE,
} from '~/lib/utils/keycodes';
import { __ } from '~/locale';
import { addClassIfElementExists } from '../lib/utils/dom_utils';
import { visitUrl, getUrlParamsArray, getParameterByName } from '../lib/utils/url_utility';
import FilteredSearchContainer from './container';
import DropdownUtils from './dropdown_utils';
import eventHub from './event_hub';
import FilteredSearchDropdownManager from './filtered_search_dropdown_manager';
import FilteredSearchTokenizer from './filtered_search_tokenizer';
import FilteredSearchVisualTokens from './filtered_search_visual_tokens';
import RecentSearchesRoot from './recent_searches_root';
import RecentSearchesService from './services/recent_searches_service';
import RecentSearchesStore from './stores/recent_searches_store';

export default class FilteredSearchManager {
  constructor({
    page,
    isGroup = false,
    isGroupAncestor = true,
    isGroupDecendent = false,
    useDefaultState = false,
    filteredSearchTokenKeys = IssuableFilteredSearchTokenKeys,
    stateFiltersSelector = '.issues-state-filters',
    placeholder = __('Search or filter results...'),
    anchor = null,
  }) {
    this.isGroup = isGroup;
    this.isGroupAncestor = isGroupAncestor;
    this.isGroupDecendent = isGroupDecendent;
    this.useDefaultState = useDefaultState;
    this.states = ['opened', 'closed', 'merged', 'all'];

    this.page = page;
    this.container = FilteredSearchContainer.container;
    this.filteredSearchInput = this.container.querySelector('.filtered-search');
    this.filteredSearchInputForm = this.filteredSearchInput.form;
    this.clearSearchButton = this.container.querySelector('.clear-search');
    this.tokensContainer = this.container.querySelector('.tokens-container');
    this.filteredSearchTokenKeys = filteredSearchTokenKeys;
    this.stateFiltersSelector = stateFiltersSelector;
    this.placeholder = placeholder;
    this.anchor = anchor;

    const {
      multipleAssignees,
      epicsEndpoint,
      iterationsEndpoint,
    } = this.filteredSearchInput.dataset;

    if (multipleAssignees && this.filteredSearchTokenKeys.enableMultipleAssignees) {
      this.filteredSearchTokenKeys.enableMultipleAssignees();
    }

    if (!epicsEndpoint && this.filteredSearchTokenKeys.removeEpicToken) {
      this.filteredSearchTokenKeys.removeEpicToken();
    }

    if (!iterationsEndpoint && this.filteredSearchTokenKeys.removeIterationToken) {
      this.filteredSearchTokenKeys.removeIterationToken();
    }

    this.recentSearchesStore = new RecentSearchesStore({
      isLocalStorageAvailable: RecentSearchesService.isAvailable(),
      allowedKeys: this.filteredSearchTokenKeys.getKeys(),
    });
    this.searchHistoryDropdownElement = document.querySelector(
      '.js-filtered-search-history-dropdown',
    );
    const fullPath = this.searchHistoryDropdownElement
      ? this.searchHistoryDropdownElement.dataset.fullPath
      : 'project';
    const recentSearchesKey = `${fullPath}-${recentSearchesStorageKeys[this.page]}`;
    this.recentSearchesService = new RecentSearchesService(recentSearchesKey);
  }

  static notTransformableQueryParams = ['scope', 'utf8', 'state', 'search'];

  setup() {
    // Fetch recent searches from localStorage
    this.fetchingRecentSearchesPromise = this.recentSearchesService
      .fetch()
      .catch((error) => {
        if (error.name === 'RecentSearchesServiceError') return undefined;
        createFlash({
          message: __('An error occurred while parsing recent searches'),
        });
        // Gracefully fail to empty array
        return [];
      })
      .then((searches) => {
        if (!searches) {
          return;
        }

        // Put any searches that may have come in before
        // we fetched the saved searches ahead of the already saved ones
        const resultantSearches = this.recentSearchesStore.setRecentSearches(
          this.recentSearchesStore.state.recentSearches.concat(searches),
        );
        this.recentSearchesService.save(resultantSearches);
      });

    if (this.filteredSearchInput) {
      this.tokenizer = FilteredSearchTokenizer;

      const {
        runnerTagsEndpoint = '',
        labelsEndpoint = '',
        milestonesEndpoint = '',
        releasesEndpoint = '',
        environmentsEndpoint = '',
        epicsEndpoint = '',
        iterationsEndpoint = '',
      } = this.filteredSearchInput.dataset;

      this.dropdownManager = new FilteredSearchDropdownManager({
        runnerTagsEndpoint,
        labelsEndpoint,
        milestonesEndpoint,
        releasesEndpoint,
        environmentsEndpoint,
        epicsEndpoint,
        iterationsEndpoint,
        tokenizer: this.tokenizer,
        page: this.page,
        isGroup: this.isGroup,
        isGroupAncestor: this.isGroupAncestor,
        isGroupDecendent: this.isGroupDecendent,
        filteredSearchTokenKeys: this.filteredSearchTokenKeys,
      });

      this.recentSearchesRoot = new RecentSearchesRoot(
        this.recentSearchesStore,
        this.recentSearchesService,
        this.searchHistoryDropdownElement,
      );
      this.recentSearchesRoot.init();

      this.bindEvents();
      this.loadSearchParamsFromURL();
      this.dropdownManager.setDropdown();
      this.cleanupWrapper = this.cleanup.bind(this);
      document.addEventListener('beforeunload', this.cleanupWrapper);
    }
  }

  cleanup() {
    this.unbindEvents();
    document.removeEventListener('beforeunload', this.cleanupWrapper);

    if (this.recentSearchesRoot) {
      this.recentSearchesRoot.destroy();
    }
  }

  bindStateEvents() {
    this.stateFilters = document.querySelector(`.container-fluid ${this.stateFiltersSelector}`);

    if (this.stateFilters) {
      this.searchStateWrapper = this.searchState.bind(this);

      this.applyToStateFilters((filterEl) => {
        filterEl.addEventListener('click', this.searchStateWrapper);
      });
    }
  }

  unbindStateEvents() {
    if (this.stateFilters) {
      this.applyToStateFilters((filterEl) => {
        filterEl.removeEventListener('click', this.searchStateWrapper);
      });
    }
  }

  applyToStateFilters(callback) {
    this.stateFilters.querySelectorAll('a[data-state]').forEach((filterEl) => {
      if (this.states.indexOf(filterEl.dataset.state) > -1) {
        callback(filterEl);
      }
    });
  }

  bindEvents() {
    this.handleFormSubmit = this.handleFormSubmit.bind(this);
    this.setDropdownWrapper = this.dropdownManager.setDropdown.bind(this.dropdownManager);
    this.toggleClearSearchButtonWrapper = this.toggleClearSearchButton.bind(this);
    this.handleInputPlaceholderWrapper = this.handleInputPlaceholder.bind(this);
    this.handleInputVisualTokenWrapper = this.handleInputVisualToken.bind(this);
    this.checkForEnterWrapper = this.checkForEnter.bind(this);
    this.onClearSearchWrapper = this.onClearSearch.bind(this);
    this.checkForBackspaceWrapper = this.checkForBackspace.call(this);
    this.checkForMetaBackspaceWrapper = this.checkForMetaBackspace.bind(this);
    this.checkForAltOrCtrlBackspaceWrapper = this.checkForAltOrCtrlBackspace.bind(this);
    this.removeSelectedTokenKeydownWrapper = this.removeSelectedTokenKeydown.bind(this);
    this.unselectEditTokensWrapper = this.unselectEditTokens.bind(this);
    this.editTokenWrapper = this.editToken.bind(this);
    this.tokenChange = this.tokenChange.bind(this);
    this.addInputContainerFocusWrapper = this.addInputContainerFocus.bind(this);
    this.removeInputContainerFocusWrapper = this.removeInputContainerFocus.bind(this);
    this.onrecentSearchesItemSelectedWrapper = this.onrecentSearchesItemSelected.bind(this);
    this.removeTokenWrapper = this.removeToken.bind(this);

    this.filteredSearchInputForm.addEventListener('submit', this.handleFormSubmit);
    this.filteredSearchInput.addEventListener('input', this.setDropdownWrapper);
    this.filteredSearchInput.addEventListener('input', this.toggleClearSearchButtonWrapper);
    this.filteredSearchInput.addEventListener('input', this.handleInputPlaceholderWrapper);
    this.filteredSearchInput.addEventListener('keyup', this.handleInputVisualTokenWrapper);
    this.filteredSearchInput.addEventListener('keydown', this.checkForEnterWrapper);
    this.filteredSearchInput.addEventListener('keyup', this.checkForBackspaceWrapper);
    // e.metaKey only works with keydown, not keyup
    this.filteredSearchInput.addEventListener('keydown', this.checkForMetaBackspaceWrapper);
    this.filteredSearchInput.addEventListener('keydown', this.checkForAltOrCtrlBackspaceWrapper);
    this.filteredSearchInput.addEventListener('click', this.tokenChange);
    this.filteredSearchInput.addEventListener('keyup', this.tokenChange);
    this.filteredSearchInput.addEventListener('focus', this.addInputContainerFocusWrapper);
    this.tokensContainer.addEventListener('click', this.removeTokenWrapper);
    this.tokensContainer.addEventListener('click', this.editTokenWrapper);
    this.clearSearchButton.addEventListener('click', this.onClearSearchWrapper);
    document.addEventListener('click', this.unselectEditTokensWrapper);
    document.addEventListener('click', this.removeInputContainerFocusWrapper);
    document.addEventListener('keydown', this.removeSelectedTokenKeydownWrapper);
    eventHub.$on('recentSearchesItemSelected', this.onrecentSearchesItemSelectedWrapper);

    this.bindStateEvents();
  }

  unbindEvents() {
    this.filteredSearchInputForm.removeEventListener('submit', this.handleFormSubmit);
    this.filteredSearchInput.removeEventListener('input', this.setDropdownWrapper);
    this.filteredSearchInput.removeEventListener('input', this.toggleClearSearchButtonWrapper);
    this.filteredSearchInput.removeEventListener('input', this.handleInputPlaceholderWrapper);
    this.filteredSearchInput.removeEventListener('keyup', this.handleInputVisualTokenWrapper);
    this.filteredSearchInput.removeEventListener('keydown', this.checkForEnterWrapper);
    this.filteredSearchInput.removeEventListener('keydown', this.checkForMetaBackspaceWrapper);
    this.filteredSearchInput.removeEventListener('keydown', this.checkForAltOrCtrlBackspaceWrapper);
    this.filteredSearchInput.removeEventListener('keyup', this.checkForBackspaceWrapper);
    this.filteredSearchInput.removeEventListener('click', this.tokenChange);
    this.filteredSearchInput.removeEventListener('keyup', this.tokenChange);
    this.filteredSearchInput.removeEventListener('focus', this.addInputContainerFocusWrapper);
    this.tokensContainer.removeEventListener('click', this.removeTokenWrapper);
    this.tokensContainer.removeEventListener('click', this.editTokenWrapper);
    this.clearSearchButton.removeEventListener('click', this.onClearSearchWrapper);
    document.removeEventListener('click', this.unselectEditTokensWrapper);
    document.removeEventListener('click', this.removeInputContainerFocusWrapper);
    document.removeEventListener('keydown', this.removeSelectedTokenKeydownWrapper);
    eventHub.$off('recentSearchesItemSelected', this.onrecentSearchesItemSelectedWrapper);

    this.unbindStateEvents();
  }

  checkForBackspace() {
    let backspaceCount = 0;

    // closure for keeping track of the number of backspace keystrokes
    return (e) => {
      // 8 = Backspace Key
      // 46 = Delete Key
      // Handled by respective backspace-combination check functions
      if (e.altKey || e.ctrlKey || e.metaKey) {
        return;
      }
      if (e.keyCode === BACKSPACE_KEY_CODE || e.keyCode === DELETE_KEY_CODE) {
        const { lastVisualToken } = FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();
        const { tokenName, tokenValue } = DropdownUtils.getVisualTokenValues(lastVisualToken);
        const canEdit = tokenName && this.canEdit && this.canEdit(tokenName, tokenValue);

        if (this.filteredSearchInput.value === '' && lastVisualToken && canEdit) {
          backspaceCount += 1;

          if (backspaceCount === 2) {
            backspaceCount = 0;
            this.filteredSearchInput.value = FilteredSearchVisualTokens.getLastTokenPartial(true);
            FilteredSearchVisualTokens.removeLastTokenPartial();
          }
        }

        // Reposition dropdown so that it is aligned with cursor
        this.dropdownManager.updateCurrentDropdownOffset();
      } else {
        backspaceCount = 0;
      }
    };
  }

  checkForAltOrCtrlBackspace(e) {
    if ((e.altKey || e.ctrlKey) && e.keyCode === BACKSPACE_KEY_CODE) {
      // Default to native OS behavior if input value present
      if (this.filteredSearchInput.value === '') {
        FilteredSearchVisualTokens.removeLastTokenPartial();
      }
    }
  }

  checkForMetaBackspace(e) {
    const onlyMeta = e.metaKey && !e.altKey && !e.ctrlKey && !e.shiftKey;
    if (onlyMeta && e.keyCode === BACKSPACE_KEY_CODE) {
      this.clearSearch();
    }
  }

  checkForEnter(e) {
    if (e.keyCode === UP_KEY_CODE || e.keyCode === DOWN_KEY_CODE) {
      const { selectionStart } = this.filteredSearchInput;

      e.preventDefault();
      this.filteredSearchInput.setSelectionRange(selectionStart, selectionStart);
    }

    if (e.keyCode === ENTER_KEY_CODE) {
      const dropdown = this.dropdownManager.mapping[this.dropdownManager.currentDropdown];
      const dropdownEl = dropdown.element;
      const activeElements = dropdownEl.querySelectorAll('.droplab-item-active');

      e.preventDefault();

      if (!activeElements.length) {
        if (this.isHandledAsync) {
          e.stopImmediatePropagation();

          this.filteredSearchInput.blur();
          this.dropdownManager.resetDropdowns();
        } else {
          // Prevent droplab from opening dropdown
          this.dropdownManager.destroyDroplab();
        }

        this.search();
      }
    }
  }

  addInputContainerFocus() {
    addClassIfElementExists(this.filteredSearchInput.closest('.filtered-search-box'), 'focus');
  }

  removeInputContainerFocus(e) {
    const inputContainer = this.filteredSearchInput.closest('.filtered-search-box');
    const isElementInFilteredSearch = inputContainer && inputContainer.contains(e.target);
    const isElementInDynamicFilterDropdown = e.target.closest('.filter-dropdown') !== null;
    const isElementInStaticFilterDropdown = e.target.closest('ul[data-dropdown]') !== null;

    if (
      !isElementInFilteredSearch &&
      !isElementInDynamicFilterDropdown &&
      !isElementInStaticFilterDropdown &&
      inputContainer
    ) {
      inputContainer.classList.remove('focus');
    }
  }

  removeToken(e) {
    const removeButtonSelected = e.target.closest('.remove-token');

    if (removeButtonSelected) {
      e.preventDefault();
      // Prevent editToken from being triggered after token is removed
      e.stopImmediatePropagation();

      const button = e.target.closest('.selectable');
      FilteredSearchVisualTokens.selectToken(button, true);
      this.removeSelectedToken();
    }
  }

  unselectEditTokens(e) {
    const inputContainer = this.container.querySelector('.filtered-search-box');
    const isElementInFilteredSearch = inputContainer && inputContainer.contains(e.target);
    const isElementInFilterDropdown = e.target.closest('.filter-dropdown') !== null;
    const isElementTokensContainer = e.target.classList.contains('tokens-container');

    if ((!isElementInFilteredSearch && !isElementInFilterDropdown) || isElementTokensContainer) {
      FilteredSearchVisualTokens.moveInputToTheRight();
      this.dropdownManager.resetDropdowns();
    }
  }

  editToken(e) {
    const token = e.target.closest('.js-visual-token');
    const sanitizedTokenName = token && token.querySelector('.name').textContent.trim();
    const canEdit = this.canEdit && this.canEdit(sanitizedTokenName);

    if (token && canEdit) {
      e.preventDefault();
      e.stopPropagation();
      FilteredSearchVisualTokens.editToken(token);
      this.tokenChange();
    }
  }

  toggleClearSearchButton() {
    const query = DropdownUtils.getSearchQuery();
    const hidden = 'hidden';
    const hasHidden = this.clearSearchButton.classList.contains(hidden);

    if (query.length === 0 && !hasHidden) {
      this.clearSearchButton.classList.add(hidden);
    } else if (query.length && hasHidden) {
      this.clearSearchButton.classList.remove(hidden);
    }
  }

  handleInputPlaceholder() {
    const query = DropdownUtils.getSearchQuery();
    const currentPlaceholder = this.filteredSearchInput.placeholder;

    if (query.length === 0 && currentPlaceholder !== this.placeholder) {
      this.filteredSearchInput.placeholder = this.placeholder;
    } else if (query.length > 0 && currentPlaceholder !== '') {
      this.filteredSearchInput.placeholder = '';
    }
  }

  removeSelectedTokenKeydown(e) {
    // 8 = Backspace Key
    // 46 = Delete Key
    if (e.keyCode === BACKSPACE_KEY_CODE || e.keyCode === DELETE_KEY_CODE) {
      this.removeSelectedToken();
    }
  }

  removeSelectedToken() {
    FilteredSearchVisualTokens.removeSelectedToken();
    this.handleInputPlaceholder();
    this.toggleClearSearchButton();
    this.dropdownManager.updateCurrentDropdownOffset();
  }

  onClearSearch(e) {
    e.preventDefault();
    this.clearSearch();
  }

  clearSearch() {
    this.filteredSearchInput.value = '';

    const removeElements = [];

    [].forEach.call(this.tokensContainer.children, (t) => {
      let canClearToken = t.classList.contains('js-visual-token');

      if (canClearToken) {
        const { tokenName, tokenValue } = DropdownUtils.getVisualTokenValues(t);
        canClearToken = this.canEdit && this.canEdit(tokenName, tokenValue);
      }

      if (canClearToken) {
        removeElements.push(t);
      }
    });

    removeElements.forEach((el) => {
      el.parentElement.removeChild(el);
    });

    this.clearSearchButton.classList.add('hidden');
    this.handleInputPlaceholder();

    this.dropdownManager.resetDropdowns();

    if (this.isHandledAsync) {
      this.search();
    }
  }

  handleInputVisualToken(e) {
    // If the keyCode was 8 then do not form new tokens
    if (e.keyCode === BACKSPACE_KEY_CODE) {
      return;
    }

    const input = this.filteredSearchInput;
    const { tokens, searchToken } = this.tokenizer.processTokens(
      input.value,
      this.filteredSearchTokenKeys.getKeys(),
    );
    const { isLastVisualTokenValid } = FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

    if (isLastVisualTokenValid) {
      tokens.forEach((t) => {
        input.value = input.value.replace(`${t.key}:${t.operator}${t.symbol}${t.value}`, '');

        FilteredSearchVisualTokens.addFilterVisualToken(
          t.key,
          t.operator,
          `${t.symbol}${t.value}`,
          {
            uppercaseTokenName: this.filteredSearchTokenKeys.shouldUppercaseTokenName(t.key),
            capitalizeTokenValue: this.filteredSearchTokenKeys.shouldCapitalizeTokenValue(t.key),
          },
        );
      });

      const fragments = searchToken.split(':');

      if (fragments.length > 1) {
        const inputValues = fragments[0].split(' ');
        const tokenKey = last(inputValues);

        if (inputValues.length > 1) {
          inputValues.pop();
          const searchTerms = inputValues.join(' ');

          input.value = input.value.replace(searchTerms, '');
          FilteredSearchVisualTokens.addSearchVisualToken(searchTerms);
        }

        FilteredSearchVisualTokens.addFilterVisualToken(tokenKey, null, null, {
          uppercaseTokenName: this.filteredSearchTokenKeys.shouldUppercaseTokenName(tokenKey),
          capitalizeTokenValue: this.filteredSearchTokenKeys.shouldCapitalizeTokenValue(tokenKey),
        });
        input.value = input.value.replace(`${tokenKey}:`, '');
      }
    } else if (!isLastVisualTokenValid && !FilteredSearchVisualTokens.getLastTokenOperator()) {
      const tokenKey = FilteredSearchVisualTokens.getLastTokenPartial();
      const tokenOperator = searchToken && searchToken.trim();

      // Tokenize operator only if the operator token is valid
      if (FilteredSearchVisualTokens.permissibleOperatorValues.includes(tokenOperator)) {
        FilteredSearchVisualTokens.removeLastTokenPartial();
        FilteredSearchVisualTokens.addFilterVisualToken(tokenKey, tokenOperator, null, {
          capitalizeTokenValue: this.filteredSearchTokenKeys.shouldCapitalizeTokenValue(tokenKey),
        });
        input.value = input.value.replace(searchToken, '').trim();
      }
    } else {
      // Keep listening to token until we determine that the user is done typing the token value
      const valueCompletedRegex = /([~%@]{0,1}".+")|([~%@]{0,1}'.+')|^((?![~%@]')(?![~%@]")(?!')(?!")).*/g;

      if (searchToken.match(valueCompletedRegex) && input.value[input.value.length - 1] === ' ') {
        const tokenKey = FilteredSearchVisualTokens.getLastTokenPartial();
        FilteredSearchVisualTokens.addFilterVisualToken(searchToken, null, null, {
          capitalizeTokenValue: this.filteredSearchTokenKeys.shouldCapitalizeTokenValue(tokenKey),
        });

        // Trim the last space as seen in the if statement above
        input.value = input.value.replace(searchToken, '').trim();
      }
    }
  }

  handleFormSubmit(e) {
    e.preventDefault();
    this.search();
  }

  saveCurrentSearchQuery() {
    // Don't save before we have fetched the already saved searches
    this.fetchingRecentSearchesPromise
      .then(() => {
        const searchQuery = DropdownUtils.getSearchQuery();
        if (searchQuery.length > 0) {
          const resultantSearches = this.recentSearchesStore.addRecentSearch(searchQuery);
          this.recentSearchesService.save(resultantSearches);
        }
      })
      .catch(() => {
        // https://gitlab.com/gitlab-org/gitlab-foss/issues/30821
      });
  }

  // allows for modifying params array when a param can't be included in the URL (e.g. Service Desk)
  getAllParams(urlParams) {
    return this.modifyUrlParams ? this.modifyUrlParams(urlParams) : urlParams;
  }

  transformParams(params) {
    /**
     * Extract key, value pair from the `not` query param:
     * Query param looks like not[key]=value
     *
     * Eg. not[foo]=%bar
     * key = foo; value = %bar
     */
    const notKeyValueRegex = new RegExp(/not\[(\w+)\]\[?\]?=(.*)/);

    return params.map((query) => {
      // Check if there are matches for `not` operator
      const matches = query.match(notKeyValueRegex);
      if (matches && matches.length === 3) {
        const keyParam = matches[1];
        if (
          FilteredSearchManager.notTransformableQueryParams.includes(keyParam) ||
          this.filteredSearchTokenKeys.searchByConditionUrl(query)
        ) {
          return query;
        }

        const valueParam = matches[2];
        // Not operator
        const operator = encodeURIComponent('!=');
        return `${keyParam}=${operator}${valueParam}`;
      }

      const [keyParam, valueParam] = query.split('=');

      if (
        FilteredSearchManager.notTransformableQueryParams.includes(keyParam) ||
        this.filteredSearchTokenKeys.searchByConditionUrl(query)
      ) {
        return query;
      }

      const operator = encodeURIComponent('=');
      return `${keyParam}=${operator}${valueParam}`;
    });
  }

  loadSearchParamsFromURL() {
    const urlParams = getUrlParamsArray();
    const withOperatorParams = this.transformParams(urlParams);
    const params = this.getAllParams(withOperatorParams);
    const usernameParams = this.getUsernameParams();
    let hasFilteredSearch = false;

    params.forEach((p) => {
      const split = p.split('=');
      const keyParam = decodeURIComponent(split[0]);
      const value = split[1];

      // Check if it matches edge conditions listed in this.filteredSearchTokenKeys
      const condition = this.filteredSearchTokenKeys.searchByConditionUrl(p);

      if (condition) {
        hasFilteredSearch = true;
        const canEdit = this.canEdit && this.canEdit(condition.tokenKey);
        FilteredSearchVisualTokens.addFilterVisualToken(
          condition.tokenKey,
          condition.operator,
          condition.value,
          {
            canEdit,
          },
        );
      } else {
        // Sanitize value since URL converts spaces into +
        // Replace before decode so that we know what was originally + versus the encoded +
        const sanitizedValue = value ? decodeURIComponent(value.replace(/\+/g, ' ')) : value;
        const match = this.filteredSearchTokenKeys.searchByKeyParam(keyParam);

        if (match) {
          const { key, symbol } = match;
          let quotationsToUse = '';

          if (sanitizedValue.indexOf(' ') !== -1) {
            // Prefer ", but use ' if required
            quotationsToUse = sanitizedValue.indexOf('"') === -1 ? '"' : "'";
          }

          hasFilteredSearch = true;
          const canEdit = this.canEdit && this.canEdit(key, sanitizedValue);
          const { uppercaseTokenName, capitalizeTokenValue } = match;
          const operator = FilteredSearchVisualTokens.getOperatorToken(sanitizedValue);
          const sanitizedToken = FilteredSearchVisualTokens.getValueToken(sanitizedValue);
          FilteredSearchVisualTokens.addFilterVisualToken(
            key,
            operator,
            `${symbol}${quotationsToUse}${sanitizedToken}${quotationsToUse}`,
            {
              canEdit,
              uppercaseTokenName,
              capitalizeTokenValue,
            },
          );
        } else if (!match && keyParam === 'assignee_id') {
          const id = parseInt(value, 10);
          if (usernameParams[id]) {
            hasFilteredSearch = true;
            const tokenName = 'assignee';
            const canEdit = this.canEdit && this.canEdit(tokenName);
            const operator = FilteredSearchVisualTokens.getOperatorToken(usernameParams[id]);
            const valueToken = FilteredSearchVisualTokens.getValueToken(usernameParams[id]);

            FilteredSearchVisualTokens.addFilterVisualToken(tokenName, operator, `@${valueToken}`, {
              canEdit,
            });
          }
        } else if (!match && keyParam === 'author_id') {
          const id = parseInt(value, 10);
          if (usernameParams[id]) {
            hasFilteredSearch = true;
            const tokenName = 'author';
            const canEdit = this.canEdit && this.canEdit(tokenName);
            const operator = FilteredSearchVisualTokens.getOperatorToken(usernameParams[id]);
            const valueToken = FilteredSearchVisualTokens.getValueToken(usernameParams[id]);

            FilteredSearchVisualTokens.addFilterVisualToken(tokenName, operator, `@${valueToken}`, {
              canEdit,
            });
          }
        } else if (!match && keyParam === 'search') {
          hasFilteredSearch = true;
          this.filteredSearchInput.value = sanitizedValue;
        }
      }
    });

    this.saveCurrentSearchQuery();

    if (hasFilteredSearch) {
      this.clearSearchButton.classList.remove('hidden');
      this.handleInputPlaceholder();
    }
  }

  searchState(e) {
    e.preventDefault();
    const target = e.currentTarget;
    // remove focus outline after click
    target.blur();

    const state = target.dataset && target.dataset.state;

    if (state) {
      this.search(state);
    }
  }

  getSearchTokens() {
    const searchQuery = DropdownUtils.getSearchQuery();
    this.saveCurrentSearchQuery();

    const tokenKeys = this.filteredSearchTokenKeys.getKeys();
    return this.tokenizer.processTokens(searchQuery, tokenKeys);
  }

  search(state = null) {
    const paths = [];
    const { tokens, searchToken } = this.getSearchTokens();
    let currentState = state || getParameterByName('state');
    if (!currentState && this.useDefaultState) {
      currentState = 'opened';
    }
    if (this.states.includes(currentState)) {
      paths.push(`state=${currentState}`);
    }

    tokens.forEach((token) => {
      const condition = this.filteredSearchTokenKeys.searchByConditionKeyValue(
        token.key,
        token.operator,
        token.value,
      );
      const tokenConfig = this.filteredSearchTokenKeys.searchByKey(token.key) || {};
      const { param } = tokenConfig;

      // Replace hyphen with underscore to use as request parameter
      // e.g. 'my-reaction' => 'my_reaction'
      const underscoredKey = token.key.replace('-', '_');
      const keyParam = param ? `${underscoredKey}_${param}` : underscoredKey;
      let tokenPath = '';

      if (condition) {
        tokenPath = condition.replacementUrl || condition.url;
      } else {
        let tokenValue = token.value;

        if (tokenConfig.lowercaseValueOnSubmit) {
          tokenValue = tokenValue.toLowerCase();
        }

        if (
          (tokenValue[0] === "'" && tokenValue[tokenValue.length - 1] === "'") ||
          (tokenValue[0] === '"' && tokenValue[tokenValue.length - 1] === '"')
        ) {
          tokenValue = tokenValue.slice(1, tokenValue.length - 1);
        }

        if (token.operator === '!=') {
          const isArrayParam = keyParam.endsWith('[]');

          tokenPath = `not[${isArrayParam ? keyParam.slice(0, -2) : keyParam}]${
            isArrayParam ? '[]' : ''
          }=${encodeURIComponent(tokenValue)}`;
        } else {
          // Default operator is `=`
          tokenPath = `${keyParam}=${encodeURIComponent(tokenValue)}`;
        }
      }

      paths.push(tokenPath);
    });

    if (searchToken) {
      const sanitized = searchToken
        .split(' ')
        .map((t) => encodeURIComponent(t))
        .join('+');
      paths.push(`search=${sanitized}`);
    }

    let parameterizedUrl = `?scope=all&${paths.join('&')}`;

    if (this.anchor) {
      parameterizedUrl += `#${this.anchor}`;
    }

    if (this.updateObject) {
      this.updateObject(parameterizedUrl);
    } else {
      visitUrl(parameterizedUrl);
    }
  }

  getUsernameParams() {
    const usernamesById = {};
    try {
      const attribute = this.filteredSearchInput.getAttribute('data-username-params');
      JSON.parse(attribute).forEach((user) => {
        usernamesById[user.id] = user.username;
      });
    } catch (e) {
      // do nothing
    }
    return usernamesById;
  }

  tokenChange() {
    const dropdown = this.dropdownManager.mapping[this.dropdownManager.currentDropdown];

    if (dropdown) {
      const currentDropdownRef = dropdown.reference;

      this.setDropdownWrapper();
      currentDropdownRef.dispatchInputEvent();
    }
  }

  onrecentSearchesItemSelected(text) {
    this.clearSearch();
    this.filteredSearchInput.value = text;
    this.filteredSearchInput.dispatchEvent(new CustomEvent('input'));
    this.search();
  }

  // eslint-disable-next-line class-methods-use-this
  canEdit() {
    return true;
  }
}
