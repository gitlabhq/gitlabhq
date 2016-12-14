/* global Turbolinks */

(() => {
  class FilteredSearchManager {
    constructor() {
      this.tokenizer = gl.FilteredSearchTokenizer;
      this.filteredSearchInput = document.querySelector('.filtered-search');
      this.clearSearchButton = document.querySelector('.clear-search');
      this.dropdownManager = new gl.FilteredSearchDropdownManager();

      this.bindEvents();
      this.loadSearchParamsFromURL();
      this.dropdownManager.setDropdown();

      this.cleanupWrapper = this.cleanup.bind(this);
      document.addEventListener('page:fetch', this.cleanupWrapper);
    }

    cleanup() {
      this.unbindEvents();
      document.removeEventListener('page:fetch', this.cleanupWrapper);
    }

    bindEvents() {
      this.setDropdownWrapper = this.dropdownManager.setDropdown.bind(this.dropdownManager);
      this.toggleClearSearchButtonWrapper = this.toggleClearSearchButton.bind(this);
      this.checkForEnterWrapper = this.checkForEnter.bind(this);
      this.clearSearchWrapper = this.clearSearch.bind(this);
      this.checkForBackspaceWrapper = this.checkForBackspace.bind(this);

      this.filteredSearchInput.addEventListener('input', this.setDropdownWrapper);
      this.filteredSearchInput.addEventListener('input', this.toggleClearSearchButtonWrapper);
      this.filteredSearchInput.addEventListener('keydown', this.checkForEnterWrapper);
      this.filteredSearchInput.addEventListener('keyup', this.checkForBackspaceWrapper);
      this.clearSearchButton.addEventListener('click', this.clearSearchWrapper);
    }

    unbindEvents() {
      this.filteredSearchInput.removeEventListener('input', this.setDropdownWrapper);
      this.filteredSearchInput.removeEventListener('input', this.toggleClearSearchButtonWrapper);
      this.filteredSearchInput.removeEventListener('keydown', this.checkForEnterWrapper);
      this.filteredSearchInput.removeEventListener('keyup', this.checkForBackspaceWrapper);
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
      if (e.keyCode === 13) {
        e.preventDefault();

        // Prevent droplab from opening dropdown
        this.dropdownManager.destroyDroplab();

        this.search();
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

    loadSearchParamsFromURL() {
      const params = gl.utils.getUrlParamsArray();
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
            const sanitizedKey = keyParam.slice(0, keyParam.indexOf('_'));
            const symbol = match.symbol;
            let quotationsToUse = '';

            if (sanitizedValue.indexOf(' ') !== -1) {
              // Prefer ", but use ' if required
              quotationsToUse = sanitizedValue.indexOf('"') === -1 ? '"' : '\'';
            }

            inputValues.push(`${sanitizedKey}:${symbol}${quotationsToUse}${sanitizedValue}${quotationsToUse}`);
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
        let tokenPath = '';

        if (token.wildcard && condition) {
          tokenPath = condition.url;
        } else if (token.wildcard) {
          // wildcard means that the token does not have a symbol
          tokenPath = `${token.key}_${param}=${encodeURIComponent(token.value)}`;
        } else {
          // Remove the token symbol
          tokenPath = `${token.key}_${param}=${encodeURIComponent(token.value.slice(1))}`;
        }

        paths.push(tokenPath);
      });

      if (searchToken) {
        paths.push(`search=${encodeURIComponent(searchToken)}`);
      }

      Turbolinks.visit(`?scope=all&utf8=✓&${paths.join('&')}`);
    }
  }

  window.gl = window.gl || {};
  gl.FilteredSearchManager = FilteredSearchManager;
})();
