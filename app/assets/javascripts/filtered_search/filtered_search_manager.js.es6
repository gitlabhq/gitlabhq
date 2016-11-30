/* eslint-disable no-param-reassign */
((global) => {
  function clearSearch(e) {
    e.stopPropagation();
    e.preventDefault();

    document.querySelector('.filtered-search').value = '';
    document.querySelector('.clear-search').classList.add('hidden');
  }

  function toggleClearSearchButton(e) {
    const clearSearchButton = document.querySelector('.clear-search');

    if (e.target.value) {
      clearSearchButton.classList.remove('hidden');
    } else {
      clearSearchButton.classList.add('hidden');
    }
  }

  function loadSearchParamsFromURL() {
    // We can trust that each param has one & since values containing & will be encoded
    // Remove the first character of search as it is always ?
    const params = window.location.search.slice(1).split('&');
    let inputValue = '';

    params.forEach((p) => {
      const split = p.split('=');
      const key = decodeURIComponent(split[0]);
      const value = split[1];

      // Check if it matches edge conditions listed in gl.FilteredSearchTokenKeys.get()
      let conditionIndex = 0;
      const validCondition = gl.FilteredSearchTokenKeys.get()
        .filter(v => v.conditions && v.conditions.filter((c, index) => {
          if (c.url === p) {
            conditionIndex = index;
          }
          return c.url === p;
        })[0])[0];

      if (validCondition) {
        inputValue += `${validCondition.key}:${validCondition.conditions[conditionIndex].keyword}`;
      } else {
        // Sanitize value since URL converts spaces into +
        // Replace before decode so that we know what was originally + versus the encoded +
        const sanitizedValue = value ? decodeURIComponent(value.replace(/[+]/g, ' ')) : value;
        const match = gl.FilteredSearchTokenKeys.get().filter(t => key === `${t.key}_${t.param}`)[0];

        if (match) {
          const sanitizedKey = key.slice(0, key.indexOf('_'));
          const valueHasSpace = sanitizedValue.indexOf(' ') !== -1;
          const symbol = match.symbol;

          const preferredQuotations = '"';
          let quotationsToUse = preferredQuotations;

          if (valueHasSpace) {
            // Prefer ", but use ' if required
            quotationsToUse = sanitizedValue.indexOf(preferredQuotations) === -1 ? preferredQuotations : '\'';
          }

          inputValue += valueHasSpace ? `${sanitizedKey}:${symbol}${quotationsToUse}${sanitizedValue}${quotationsToUse}` : `${sanitizedKey}:${symbol}${sanitizedValue}`;
          inputValue += ' ';
        } else if (!match && key === 'search') {
          inputValue += sanitizedValue;
          inputValue += ' ';
        }
      }
    });

    // Trim the last space value
    document.querySelector('.filtered-search').value = inputValue.trim();

    if (inputValue.trim()) {
      document.querySelector('.clear-search').classList.remove('hidden');
    }
  }

  class FilteredSearchManager {
    constructor() {
      this.tokenizer = gl.FilteredSearchTokenizer;
      this.bindEvents();
      loadSearchParamsFromURL();
    }

    bindEvents() {
      const filteredSearchInput = document.querySelector('.filtered-search');

      filteredSearchInput.addEventListener('input', this.processInput.bind(this));
      filteredSearchInput.addEventListener('input', toggleClearSearchButton);
      filteredSearchInput.addEventListener('keydown', this.checkForEnter.bind(this));

      document.querySelector('.clear-search').addEventListener('click', clearSearch);
    }

    // TODO: This is only used for testing, remove when going to PRO
    processInput(e) {
      const input = e.target.value;
      this.tokenizer.processTokens(input);
    }

    checkForEnter(e) {
      // Enter KeyCode
      if (e.keyCode === 13) {
        e.stopPropagation();
        e.preventDefault();
        this.search();
      }
    }

    search() {
      console.log('search');
      let path = '?scope=all&utf8=✓';

      // Check current state
      const currentPath = window.location.search;
      const stateIndex = currentPath.indexOf('state=');
      const defaultState = 'opened';
      let currentState = defaultState;

      const { tokens, searchToken } = this.tokenizer.processTokens(document.querySelector('.filtered-search').value);

      if (stateIndex !== -1) {
        const remaining = currentPath.slice(stateIndex + 6);
        const separatorIndex = remaining.indexOf('&');

        currentState = separatorIndex === -1 ? remaining : remaining.slice(0, separatorIndex);
      }

      path += `&state=${currentState}`;
      tokens.forEach((token) => {
        const match = gl.FilteredSearchTokenKeys.get().filter(t => t.key === token.key)[0];
        let tokenPath = '';

        if (token.wildcard && match.conditions) {
          const condition = match.conditions
            .filter(c => c.keyword === token.value.toLowerCase())[0];

          if (condition) {
            tokenPath = `${condition.url}`;
          }
        } else if (!token.wildcard) {
          // Remove the wildcard token
          tokenPath = `${token.key}_${match.param}=${encodeURIComponent(token.value.slice(1))}`;
        } else {
          tokenPath = `${token.key}_${match.param}=${encodeURIComponent(token.value)}`;
        }

        path += `&${tokenPath}`;
      });

      if (searchToken) {
        path += `&search=${encodeURIComponent(searchToken)}`;
      }

      window.location = path;
    }
  }

  global.FilteredSearchManager = FilteredSearchManager;
})(window.gl || (window.gl = {}));
