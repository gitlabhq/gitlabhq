import FilteredSearchContainer from './container';

(() => {
  class FilteredSearchManager {
    constructor(page) {
      this.container = FilteredSearchContainer.container;
      this.filteredSearchInput = this.container.querySelector('.filtered-search');
      this.clearSearchButton = this.container.querySelector('.clear-search');
      this.tokensContainer = this.container.querySelector('.tokens-container');
      this.filteredSearchTokenKeys = gl.FilteredSearchTokenKeys;

      if (this.filteredSearchInput) {
        this.tokenizer = gl.FilteredSearchTokenizer;
        this.dropdownManager = new gl.FilteredSearchDropdownManager(this.filteredSearchInput.getAttribute('data-base-endpoint') || '', page);

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
    }

    bindEvents() {
      this.handleFormSubmit = this.handleFormSubmit.bind(this);
      this.setDropdownWrapper = this.dropdownManager.setDropdown.bind(this.dropdownManager);
      this.toggleClearSearchButtonWrapper = this.toggleClearSearchButton.bind(this);
      this.handleInputPlaceholderWrapper = this.handleInputPlaceholder.bind(this);
      this.handleInputVisualTokenWrapper = this.handleInputVisualToken.bind(this);
      this.checkForEnterWrapper = this.checkForEnter.bind(this);
      this.clearSearchWrapper = this.clearSearch.bind(this);
      this.checkForBackspaceWrapper = this.checkForBackspace.bind(this);
      this.removeSelectedTokenWrapper = this.removeSelectedToken.bind(this);
      this.unselectEditTokensWrapper = this.unselectEditTokens.bind(this);
      this.editTokenWrapper = this.editToken.bind(this);
      this.tokenChange = this.tokenChange.bind(this);

      this.filteredSearchInputForm = this.filteredSearchInput.form;
      this.filteredSearchInputForm.addEventListener('submit', this.handleFormSubmit);
      this.filteredSearchInput.addEventListener('input', this.setDropdownWrapper);
      this.filteredSearchInput.addEventListener('input', this.toggleClearSearchButtonWrapper);
      this.filteredSearchInput.addEventListener('input', this.handleInputPlaceholderWrapper);
      this.filteredSearchInput.addEventListener('input', this.handleInputVisualTokenWrapper);
      this.filteredSearchInput.addEventListener('keydown', this.checkForEnterWrapper);
      this.filteredSearchInput.addEventListener('keyup', this.checkForBackspaceWrapper);
      this.filteredSearchInput.addEventListener('click', this.tokenChange);
      this.filteredSearchInput.addEventListener('keyup', this.tokenChange);
      this.tokensContainer.addEventListener('click', FilteredSearchManager.selectToken);
      this.tokensContainer.addEventListener('dblclick', this.editTokenWrapper);
      this.clearSearchButton.addEventListener('click', this.clearSearchWrapper);
      document.addEventListener('click', gl.FilteredSearchVisualTokens.unselectTokens);
      document.addEventListener('click', this.unselectEditTokensWrapper);
      document.addEventListener('keydown', this.removeSelectedTokenWrapper);
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
      this.tokensContainer.removeEventListener('click', FilteredSearchManager.selectToken);
      this.tokensContainer.removeEventListener('dblclick', this.editTokenWrapper);
      this.clearSearchButton.removeEventListener('click', this.clearSearchWrapper);
      document.removeEventListener('click', gl.FilteredSearchVisualTokens.unselectTokens);
      document.removeEventListener('click', this.unselectEditTokensWrapper);
      document.removeEventListener('keydown', this.removeSelectedTokenWrapper);
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
        const activeElements = dropdownEl.querySelectorAll('.dropdown-active');

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

    static selectToken(e) {
      const button = e.target.closest('.selectable');

      if (button) {
        e.preventDefault();
        e.stopPropagation();
        gl.FilteredSearchVisualTokens.selectToken(button);
      }
    }

    unselectEditTokens(e) {
      const inputContainer = this.container.querySelector('.filtered-search-input-container');
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

    clearSearch(e) {
      e.preventDefault();

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

      if (hasFilteredSearch) {
        this.clearSearchButton.classList.remove('hidden');
        this.handleInputPlaceholder();
      }
    }

    search() {
      const paths = [];
      const { tokens, searchToken }
        = this.tokenizer.processTokens(gl.DropdownUtils.getSearchQuery());
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

      const parameterizedUrl = `?scope=all&utf8=✓&${paths.join('&')}`;

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
  }

  window.gl = window.gl || {};
  gl.FilteredSearchManager = FilteredSearchManager;
})();
