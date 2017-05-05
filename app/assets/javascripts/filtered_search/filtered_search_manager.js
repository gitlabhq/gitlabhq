import FilteredSearchContainer from './container';
import RecentSearchesRoot from './recent_searches_root';
import RecentSearchesStore from './stores/recent_searches_store';
import RecentSearchesService from './services/recent_searches_service';
import eventHub from './event_hub';

(() => {
  class FilteredSearchManager {
    constructor(page) {
      this.container = FilteredSearchContainer.container;
      this.filteredSearchInput = this.container.querySelector('.filtered-search');
      this.filteredSearchInputForm = this.filteredSearchInput.form;
      this.clearSearchButton = this.container.querySelector('.clear-search');
      this.tokensContainer = this.container.querySelector('.tokens-container');
      this.filteredSearchTokenKeys = gl.FilteredSearchTokenKeys;

      this.recentSearchesStore = new RecentSearchesStore({
        isLocalStorageAvailable: RecentSearchesService.isAvailable(),
      });
      let recentSearchesKey = 'issue-recent-searches';
      if (page === 'merge_requests') {
        recentSearchesKey = 'merge-request-recent-searches';
      }
      this.recentSearchesService = new RecentSearchesService(recentSearchesKey);

      // Fetch recent searches from localStorage
      this.fetchingRecentSearchesPromise = this.recentSearchesService.fetch()
        .catch((error) => {
          if (error.name === 'RecentSearchesServiceError') return undefined;
          // eslint-disable-next-line no-new
          new window.Flash('An error occured while parsing recent searches');
          // Gracefully fail to empty array
          return [];
        })
        .then((searches) => {
          // Put any searches that may have come in before
          // we fetched the saved searches ahead of the already saved ones
          const resultantSearches = this.recentSearchesStore.setRecentSearches(
            this.recentSearchesStore.state.recentSearches.concat(searches),
          );
          this.recentSearchesService.save(resultantSearches);
        });

      if (this.filteredSearchInput) {
        this.tokenizer = gl.FilteredSearchTokenizer;
        this.dropdownManager = new gl.FilteredSearchDropdownManager(this.filteredSearchInput.getAttribute('data-base-endpoint') || '', page);

        this.recentSearchesRoot = new RecentSearchesRoot(
          this.recentSearchesStore,
          this.recentSearchesService,
          document.querySelector('.js-filtered-search-history-dropdown'),
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

    bindEvents() {
      this.handleFormSubmit = this.handleFormSubmit.bind(this);
      this.setDropdownWrapper = this.dropdownManager.setDropdown.bind(this.dropdownManager);
      this.toggleClearSearchButtonWrapper = this.toggleClearSearchButton.bind(this);
      this.handleInputPlaceholderWrapper = this.handleInputPlaceholder.bind(this);
      this.handleInputVisualTokenWrapper = this.handleInputVisualToken.bind(this);
      this.checkForEnterWrapper = this.checkForEnter.bind(this);
      this.onClearSearchWrapper = this.onClearSearch.bind(this);
      this.checkForBackspaceWrapper = this.checkForBackspace.bind(this);
      this.removeSelectedTokenWrapper = this.removeSelectedToken.bind(this);
      this.unselectEditTokensWrapper = this.unselectEditTokens.bind(this);
      this.editTokenWrapper = this.editToken.bind(this);
      this.tokenChange = this.tokenChange.bind(this);
      this.addInputContainerFocusWrapper = this.addInputContainerFocus.bind(this);
      this.removeInputContainerFocusWrapper = this.removeInputContainerFocus.bind(this);
      this.onrecentSearchesItemSelectedWrapper = this.onrecentSearchesItemSelected.bind(this);

      this.filteredSearchInputForm.addEventListener('submit', this.handleFormSubmit);
      this.filteredSearchInput.addEventListener('input', this.setDropdownWrapper);
      this.filteredSearchInput.addEventListener('input', this.toggleClearSearchButtonWrapper);
      this.filteredSearchInput.addEventListener('input', this.handleInputPlaceholderWrapper);
      this.filteredSearchInput.addEventListener('input', this.handleInputVisualTokenWrapper);
      this.filteredSearchInput.addEventListener('keydown', this.checkForEnterWrapper);
      this.filteredSearchInput.addEventListener('keyup', this.checkForBackspaceWrapper);
      this.filteredSearchInput.addEventListener('click', this.tokenChange);
      this.filteredSearchInput.addEventListener('keyup', this.tokenChange);
      this.filteredSearchInput.addEventListener('focus', this.addInputContainerFocusWrapper);
      this.tokensContainer.addEventListener('click', FilteredSearchManager.selectToken);
      this.tokensContainer.addEventListener('dblclick', this.editTokenWrapper);
      this.clearSearchButton.addEventListener('click', this.onClearSearchWrapper);
      document.addEventListener('click', gl.FilteredSearchVisualTokens.unselectTokens);
      document.addEventListener('click', this.unselectEditTokensWrapper);
      document.addEventListener('click', this.removeInputContainerFocusWrapper);
      document.addEventListener('keydown', this.removeSelectedTokenWrapper);
      eventHub.$on('recentSearchesItemSelected', this.onrecentSearchesItemSelectedWrapper);
    }

    unbindEvents() {
      this.filteredSearchInputForm.removeEventListener('submit', this.handleFormSubmit);
      this.filteredSearchInput.removeEventListener('input', this.setDropdownWrapper);
      this.filteredSearchInput.removeEventListener('input', this.toggleClearSearchButtonWrapper);
      this.filteredSearchInput.removeEventListener('input', this.handleInputPlaceholderWrapper);
      this.filteredSearchInput.removeEventListener('input', this.handleInputVisualTokenWrapper);
      this.filteredSearchInput.removeEventListener('keydown', this.checkForEnterWrapper);
      this.filteredSearchInput.removeEventListener('keyup', this.checkForBackspaceWrapper);
      this.filteredSearchInput.removeEventListener('click', this.tokenChange);
      this.filteredSearchInput.removeEventListener('keyup', this.tokenChange);
      this.filteredSearchInput.removeEventListener('focus', this.addInputContainerFocusWrapper);
      this.tokensContainer.removeEventListener('click', FilteredSearchManager.selectToken);
      this.tokensContainer.removeEventListener('dblclick', this.editTokenWrapper);
      this.clearSearchButton.removeEventListener('click', this.onClearSearchWrapper);
      document.removeEventListener('click', gl.FilteredSearchVisualTokens.unselectTokens);
      document.removeEventListener('click', this.unselectEditTokensWrapper);
      document.removeEventListener('click', this.removeInputContainerFocusWrapper);
      document.removeEventListener('keydown', this.removeSelectedTokenWrapper);
      eventHub.$off('recentSearchesItemSelected', this.onrecentSearchesItemSelectedWrapper);
    }

    checkForBackspace(e) {
      // 8 = Backspace Key
      // 46 = Delete Key
      if (e.keyCode === 8 || e.keyCode === 46) {
        const { lastVisualToken } = gl.FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

        if (this.filteredSearchInput.value === '' && lastVisualToken) {
          this.filteredSearchInput.value = gl.FilteredSearchVisualTokens.getLastTokenPartial();
          gl.FilteredSearchVisualTokens.removeLastTokenPartial();
        }

        // Reposition dropdown so that it is aligned with cursor
        this.dropdownManager.updateCurrentDropdownOffset();
      }
    }

    checkForEnter(e) {
      if (e.keyCode === 38 || e.keyCode === 40) {
        const selectionStart = this.filteredSearchInput.selectionStart;

        e.preventDefault();
        this.filteredSearchInput.setSelectionRange(selectionStart, selectionStart);
      }

      if (e.keyCode === 13) {
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
      const inputContainer = this.filteredSearchInput.closest('.filtered-search-box');

      if (inputContainer) {
        inputContainer.classList.add('focus');
      }
    }

    removeInputContainerFocus(e) {
      const inputContainer = this.filteredSearchInput.closest('.filtered-search-box');
      const isElementInFilteredSearch = inputContainer && inputContainer.contains(e.target);
      const isElementInDynamicFilterDropdown = e.target.closest('.filter-dropdown') !== null;
      const isElementInStaticFilterDropdown = e.target.closest('ul[data-dropdown]') !== null;

      if (!isElementInFilteredSearch && !isElementInDynamicFilterDropdown &&
        !isElementInStaticFilterDropdown && inputContainer) {
        inputContainer.classList.remove('focus');
      }
    }

    static selectToken(e) {
      const button = e.target.closest('.selectable');

      if (button) {
        e.preventDefault();
        e.stopPropagation();
        gl.FilteredSearchVisualTokens.selectToken(button);
      }
    }

    unselectEditTokens(e) {
      const inputContainer = this.container.querySelector('.filtered-search-box');
      const isElementInFilteredSearch = inputContainer && inputContainer.contains(e.target);
      const isElementInFilterDropdown = e.target.closest('.filter-dropdown') !== null;
      const isElementTokensContainer = e.target.classList.contains('tokens-container');

      if ((!isElementInFilteredSearch && !isElementInFilterDropdown) || isElementTokensContainer) {
        gl.FilteredSearchVisualTokens.moveInputToTheRight();
        this.dropdownManager.resetDropdowns();
      }
    }

    editToken(e) {
      const token = e.target.closest('.js-visual-token');

      if (token) {
        gl.FilteredSearchVisualTokens.editToken(token);
        this.tokenChange();
      }
    }

    toggleClearSearchButton() {
      const query = gl.DropdownUtils.getSearchQuery();
      const hidden = 'hidden';
      const hasHidden = this.clearSearchButton.classList.contains(hidden);

      if (query.length === 0 && !hasHidden) {
        this.clearSearchButton.classList.add(hidden);
      } else if (query.length && hasHidden) {
        this.clearSearchButton.classList.remove(hidden);
      }
    }

    handleInputPlaceholder() {
      const query = gl.DropdownUtils.getSearchQuery();
      const placeholder = 'Search or filter results...';
      const currentPlaceholder = this.filteredSearchInput.placeholder;

      if (query.length === 0 && currentPlaceholder !== placeholder) {
        this.filteredSearchInput.placeholder = placeholder;
      } else if (query.length > 0 && currentPlaceholder !== '') {
        this.filteredSearchInput.placeholder = '';
      }
    }

    removeSelectedToken(e) {
      // 8 = Backspace Key
      // 46 = Delete Key
      if (e.keyCode === 8 || e.keyCode === 46) {
        gl.FilteredSearchVisualTokens.removeSelectedToken();
        this.handleInputPlaceholder();
        this.toggleClearSearchButton();
      }
    }

    onClearSearch(e) {
      e.preventDefault();
      this.clearSearch();
    }

    clearSearch() {
      this.filteredSearchInput.value = '';

      const removeElements = [];

      [].forEach.call(this.tokensContainer.children, (t) => {
        if (t.classList.contains('js-visual-token')) {
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

    handleInputVisualToken() {
      const input = this.filteredSearchInput;
      const { tokens, searchToken }
        = gl.FilteredSearchTokenizer.processTokens(input.value);
      const { isLastVisualTokenValid }
        = gl.FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

      if (isLastVisualTokenValid) {
        tokens.forEach((t) => {
          input.value = input.value.replace(`${t.key}:${t.symbol}${t.value}`, '');
          gl.FilteredSearchVisualTokens.addFilterVisualToken(t.key, `${t.symbol}${t.value}`);
        });

        const fragments = searchToken.split(':');
        if (fragments.length > 1) {
          const inputValues = fragments[0].split(' ');
          const tokenKey = inputValues.last();

          if (inputValues.length > 1) {
            inputValues.pop();
            const searchTerms = inputValues.join(' ');

            input.value = input.value.replace(searchTerms, '');
            gl.FilteredSearchVisualTokens.addSearchVisualToken(searchTerms);
          }

          gl.FilteredSearchVisualTokens.addFilterVisualToken(tokenKey);
          input.value = input.value.replace(`${tokenKey}:`, '');
        }
      } else {
        // Keep listening to token until we determine that the user is done typing the token value
        const valueCompletedRegex = /([~%@]{0,1}".+")|([~%@]{0,1}'.+')|^((?![~%@]')(?![~%@]")(?!')(?!")).*/g;

        if (searchToken.match(valueCompletedRegex) && input.value[input.value.length - 1] === ' ') {
          gl.FilteredSearchVisualTokens.addFilterVisualToken(searchToken);

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
      this.fetchingRecentSearchesPromise.then(() => {
        const searchQuery = gl.DropdownUtils.getSearchQuery();
        if (searchQuery.length > 0) {
          const resultantSearches = this.recentSearchesStore.addRecentSearch(searchQuery);
          this.recentSearchesService.save(resultantSearches);
        }
      });
    }

    loadSearchParamsFromURL() {
      const params = gl.utils.getUrlParamsArray();
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
          gl.FilteredSearchVisualTokens.addFilterVisualToken(condition.tokenKey, condition.value);
        } else {
          // Sanitize value since URL converts spaces into +
          // Replace before decode so that we know what was originally + versus the encoded +
          const sanitizedValue = value ? decodeURIComponent(value.replace(/\+/g, ' ')) : value;
          const match = this.filteredSearchTokenKeys.searchByKeyParam(keyParam);

          if (match) {
            const indexOf = keyParam.indexOf('_');
            const sanitizedKey = indexOf !== -1 ? keyParam.slice(0, keyParam.indexOf('_')) : keyParam;
            const symbol = match.symbol;
            let quotationsToUse = '';

            if (sanitizedValue.indexOf(' ') !== -1) {
              // Prefer ", but use ' if required
              quotationsToUse = sanitizedValue.indexOf('"') === -1 ? '"' : '\'';
            }

            hasFilteredSearch = true;
            gl.FilteredSearchVisualTokens.addFilterVisualToken(sanitizedKey, `${symbol}${quotationsToUse}${sanitizedValue}${quotationsToUse}`);
          } else if (!match && keyParam === 'assignee_id') {
            const id = parseInt(value, 10);
            if (usernameParams[id]) {
              hasFilteredSearch = true;
              gl.FilteredSearchVisualTokens.addFilterVisualToken('assignee', `@${usernameParams[id]}`);
            }
          } else if (!match && keyParam === 'author_id') {
            const id = parseInt(value, 10);
            if (usernameParams[id]) {
              hasFilteredSearch = true;
              gl.FilteredSearchVisualTokens.addFilterVisualToken('author', `@${usernameParams[id]}`);
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

    search() {
      const paths = [];
      const searchQuery = gl.DropdownUtils.getSearchQuery();

      this.saveCurrentSearchQuery();

      const { tokens, searchToken }
        = this.tokenizer.processTokens(searchQuery);
      const currentState = gl.utils.getParameterByName('state') || 'opened';
      paths.push(`state=${currentState}`);

      tokens.forEach((token) => {
        const condition = this.filteredSearchTokenKeys
          .searchByConditionKeyValue(token.key, token.value.toLowerCase());
        const { param } = this.filteredSearchTokenKeys.searchByKey(token.key) || {};
        const keyParam = param ? `${token.key}_${param}` : token.key;
        let tokenPath = '';

        if (condition) {
          tokenPath = condition.url;
        } else {
          let tokenValue = token.value;

          if ((tokenValue[0] === '\'' && tokenValue[tokenValue.length - 1] === '\'') ||
            (tokenValue[0] === '"' && tokenValue[tokenValue.length - 1] === '"')) {
            tokenValue = tokenValue.slice(1, tokenValue.length - 1);
          }

          tokenPath = `${keyParam}=${encodeURIComponent(tokenValue)}`;
        }

        paths.push(tokenPath);
      });

      if (searchToken) {
        const sanitized = searchToken.split(' ').map(t => encodeURIComponent(t)).join('+');
        paths.push(`search=${sanitized}`);
      }

      const parameterizedUrl = `?scope=all&utf8=%E2%9C%93&${paths.join('&')}`;

      if (this.updateObject) {
        this.updateObject(parameterizedUrl);
      } else {
        gl.utils.visitUrl(parameterizedUrl);
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
  }

  window.gl = window.gl || {};
  gl.FilteredSearchManager = FilteredSearchManager;
})();
