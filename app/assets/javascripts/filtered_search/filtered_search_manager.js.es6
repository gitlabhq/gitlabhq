/* global Turbolinks */

(() => {
  class FilteredSearchManager {
    constructor() {
      this.filteredSearchInput = document.querySelector('.filtered-search');
      this.clearSearchButton = document.querySelector('.clear-search');

      if (this.filteredSearchInput) {
        this.tokenizer = gl.FilteredSearchTokenizer;
        this.dropdownManager = new gl.FilteredSearchDropdownManager(this.filteredSearchInput.getAttribute('data-base-endpoint') || '');

        this.bindEvents();
        this.loadSearchParamsFromURL();
        this.dropdownManager.setDropdown();

        this.cleanupWrapper = this.cleanup.bind(this);
        document.addEventListener('page:fetch', this.cleanupWrapper);
      }
    }

    cleanup() {
      this.unbindEvents();
      document.removeEventListener('page:fetch', this.cleanupWrapper);
    }

    bindEvents() {
      this.handleFormSubmit = this.handleFormSubmit.bind(this);
      this.setDropdownWrapper = this.dropdownManager.setDropdown.bind(this.dropdownManager);
      this.toggleClearSearchButtonWrapper = this.toggleClearSearchButton.bind(this);
      this.checkForEnterWrapper = this.checkForEnter.bind(this);
      this.clearSearchWrapper = this.clearSearch.bind(this);
      this.checkForBackspaceWrapper = this.checkForBackspace.bind(this);
      this.tokenChange = this.tokenChange.bind(this);

      this.filteredSearchInput.form.addEventListener('submit', this.handleFormSubmit);
      this.filteredSearchInput.addEventListener('input', this.setDropdownWrapper);
      this.filteredSearchInput.addEventListener('input', this.toggleClearSearchButtonWrapper);
      this.filteredSearchInput.addEventListener('keydown', this.checkForEnterWrapper);
      this.filteredSearchInput.addEventListener('keyup', this.checkForBackspaceWrapper);
      this.filteredSearchInput.addEventListener('click', this.tokenChange);
      this.filteredSearchInput.addEventListener('keyup', this.tokenChange);
      this.clearSearchButton.addEventListener('click', this.clearSearchWrapper);
    }

    unbindEvents() {
      this.filteredSearchInput.form.removeEventListener('submit', this.handleFormSubmit);
      this.filteredSearchInput.removeEventListener('input', this.setDropdownWrapper);
      this.filteredSearchInput.removeEventListener('input', this.toggleClearSearchButtonWrapper);
      this.filteredSearchInput.removeEventListener('keydown', this.checkForEnterWrapper);
      this.filteredSearchInput.removeEventListener('keyup', this.checkForBackspaceWrapper);
      this.filteredSearchInput.removeEventListener('click', this.tokenChange);
      this.filteredSearchInput.removeEventListener('keyup', this.tokenChange);
      this.clearSearchButton.removeEventListener('click', this.clearSearchWrapper);
    }

    checkForBackspace(e) {
      // 8 = Backspace Key
      // 46 = Delete Key
      if (e.keyCode === 8 || e.keyCode === 46) {
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
          // Prevent droplab from opening dropdown
          this.dropdownManager.destroyDroplab();

          this.search();
        }
      }
    }

    toggleClearSearchButton(e) {
      if (e.target.value) {
        this.clearSearchButton.classList.remove('hidden');
      } else {
        this.clearSearchButton.classList.add('hidden');
      }
    }

    clearSearch(e) {
      e.preventDefault();

      this.filteredSearchInput.value = '';
      this.clearSearchButton.classList.add('hidden');

      this.dropdownManager.resetDropdowns();
    }

    handleFormSubmit(e) {
      e.preventDefault();
      this.search();
    }

    loadSearchParamsFromURL() {
      const params = gl.utils.getUrlParamsArray();
      const usernameParams = this.getUsernameParams();
      const inputValues = [];

      params.forEach((p) => {
        const split = p.split('=');
        const keyParam = decodeURIComponent(split[0]);
        const value = split[1];

        // Check if it matches edge conditions listed in gl.FilteredSearchTokenKeys
        const condition = gl.FilteredSearchTokenKeys.searchByConditionUrl(p);

        if (condition) {
          inputValues.push(`${condition.tokenKey}:${condition.value}`);
        } else {
          // Sanitize value since URL converts spaces into +
          // Replace before decode so that we know what was originally + versus the encoded +
          const sanitizedValue = value ? decodeURIComponent(value.replace(/\+/g, ' ')) : value;
          const match = gl.FilteredSearchTokenKeys.searchByKeyParam(keyParam);

          if (match) {
            const indexOf = keyParam.indexOf('_');
            const sanitizedKey = indexOf !== -1 ? keyParam.slice(0, keyParam.indexOf('_')) : keyParam;
            const symbol = match.symbol;
            let quotationsToUse = '';

            if (sanitizedValue.indexOf(' ') !== -1) {
              // Prefer ", but use ' if required
              quotationsToUse = sanitizedValue.indexOf('"') === -1 ? '"' : '\'';
            }

            inputValues.push(`${sanitizedKey}:${symbol}${quotationsToUse}${sanitizedValue}${quotationsToUse}`);
          } else if (!match && keyParam === 'assignee_id') {
            const id = parseInt(value, 10);
            if (usernameParams[id]) {
              inputValues.push(`assignee:@${usernameParams[id]}`);
            }
          } else if (!match && keyParam === 'author_id') {
            const id = parseInt(value, 10);
            if (usernameParams[id]) {
              inputValues.push(`author:@${usernameParams[id]}`);
            }
          } else if (!match && keyParam === 'search') {
            inputValues.push(sanitizedValue);
          }
        }
      });

      // Trim the last space value
      this.filteredSearchInput.value = inputValues.join(' ');

      if (inputValues.length > 0) {
        this.clearSearchButton.classList.remove('hidden');
      }
    }

    search() {
      const paths = [];
      const { tokens, searchToken } = this.tokenizer.processTokens(this.filteredSearchInput.value);
      const currentState = gl.utils.getParameterByName('state') || 'opened';
      paths.push(`state=${currentState}`);

      tokens.forEach((token) => {
        const condition = gl.FilteredSearchTokenKeys
          .searchByConditionKeyValue(token.key, token.value.toLowerCase());
        const { param } = gl.FilteredSearchTokenKeys.searchByKey(token.key);
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

      Turbolinks.visit(`?scope=all&utf8=✓&${paths.join('&')}`);
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
      const currentDropdownRef = dropdown.reference;

      this.setDropdownWrapper();
      currentDropdownRef.dispatchInputEvent();
    }
  }

  window.gl = window.gl || {};
  gl.FilteredSearchManager = FilteredSearchManager;
})();
