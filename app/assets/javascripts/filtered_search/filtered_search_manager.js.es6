((global) => {
  const TOKEN_TYPE_STRING = 'string';
  const TOKEN_TYPE_ARRAY = 'array';

  const validTokenKeys = [{
    key: 'author',
    type: 'string',
    param: 'username',
  },{
    key: 'assignee',
    type: 'string',
    param: 'username',
  },{
    key: 'milestone',
    type: 'string',
    param: 'title',
  },{
    key: 'label',
    type: 'array',
    param: 'name[]',
  },];

  class FilteredSearchManager {
    constructor() {
      this.bindEvents();
      this.loadSearchParamsFromURL();
      this.clearTokens();
    }

    bindEvents() {
      const input = document.querySelector('.filtered-search');
      const clearSearch = document.querySelector('.clear-search');

      input.addEventListener('input', this.tokenize.bind(this));
      input.addEventListener('input', this.toggleClearSearchButton);
      input.addEventListener('keydown', this.checkForEnter.bind(this));

      clearSearch.addEventListener('click', this.clearSearch.bind(this));
    }

    clearSearch(event) {
      event.stopPropagation();
      event.preventDefault();

      this.clearTokens();
      document.querySelector('.filtered-search').value = '';
      document.querySelector('.clear-search').classList.add('hidden');
    }

    clearTokens() {
      this.tokens = [];
      this.searchToken = '';
    }

    loadSearchParamsFromURL() {
      // We can trust that each param has one & since values containing & will be encoded
      // Remove the first character of search as it is always ?
      const params = window.location.search.slice(1).split('&');
      let inputValue = '';

      params.forEach((p) => {
        const split = p.split('=');
        const key = decodeURIComponent(split[0]);
        const value = split[1];

        // Sanitize value since URL converts spaces into +
        // Replace before decode so that we know what was originally + versus the encoded +
        const sanitizedValue = value ? decodeURIComponent(value.replace(/[+]/g, ' ')) : value;

        const match = validTokenKeys.find((t) => {
          return key === `${t.key}_${t.param}`;
        });

        if (match) {
          const sanitizedKey = key.slice(0, key.indexOf('_'));
          const valueHasSpace = sanitizedValue.indexOf(' ') !== -1;

          const preferredQuotations = '"';
          let quotationsToUse = preferredQuotations;

          if (valueHasSpace) {
            // Prefer ", but use ' if required
            quotationsToUse = sanitizedValue.indexOf(preferredQuotations) === -1 ? preferredQuotations : '\'';
          }

          inputValue += valueHasSpace ? `${sanitizedKey}:${quotationsToUse}${sanitizedValue}${quotationsToUse}` : `${sanitizedKey}:${sanitizedValue}`;
          inputValue += ' ';

        } else if (!match && key === 'search') {
          inputValue += sanitizedValue;
          inputValue += ' ';
        }
      });

      // Trim the last space value
      document.querySelector('.filtered-search').value = inputValue.trim();

      if (inputValue.trim()) {
        document.querySelector('.clear-search').classList.remove('hidden');
      }
    }

    toggleClearSearchButton(event) {
      const clearSearch = document.querySelector('.clear-search');

      if (event.target.value) {
        clearSearch.classList.remove('hidden');
      } else {
        clearSearch.classList.add('hidden');
      }
    }

    tokenize(event) {
      // Re-calculate tokens
      this.clearTokens();

      const input = event.target.value;
      const inputs = input.split(' ');
      let searchTerms = '';
      let lastQuotation = '';
      let incompleteToken = false;

      const addSearchTerm = function addSearchTerm(term) {
        searchTerms += term + ' ';
      }

      inputs.forEach((i) => {
        if (incompleteToken) {
          const prevToken = this.tokens[this.tokens.length - 1];
          prevToken.value += ` ${i}`;

          // Remove last quotation
          const lastQuotationRegex = new RegExp(lastQuotation, 'g');
          prevToken.value = prevToken.value.replace(lastQuotationRegex, '');
          this.tokens[this.tokens.length - 1] = prevToken;

          // Check to see if this quotation completes the token value
          if (i.indexOf(lastQuotation)) {
            incompleteToken = !incompleteToken;
          }

          return;
        }

        const colonIndex = i.indexOf(':');

        if (colonIndex !== -1) {
          const tokenKey = i.slice(0, colonIndex).toLowerCase();
          const tokenValue = i.slice(colonIndex + 1);

          const match = validTokenKeys.find((v) => {
            return v.key === tokenKey;
          });

          if (tokenValue.indexOf('"') !== -1) {
            lastQuotation = '"';
            incompleteToken = true;
          } else if (tokenValue.indexOf('\'') !== -1) {
            lastQuotation = '\'';
            incompleteToken = true;
          }

          if (match && tokenValue.length > 0) {
            this.tokens.push({
              key: match.key,
              value: tokenValue,
            });
          } else {
            addSearchTerm(i);
          }
        } else {
          addSearchTerm(i);
        }
      }, this);

      this.searchToken = searchTerms.trim();
      this.printTokens();
    }

    printTokens() {
      console.log('tokens:')
      this.tokens.forEach((token) => {
        console.log(token);
      })
      console.log('search: ' + this.searchToken);
    }

    checkForEnter(event) {
      if (event.key === 'Enter') {
        event.stopPropagation();
        event.preventDefault();
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

      if (stateIndex !== -1) {
        const remaining = currentPath.slice(stateIndex + 6);
        const separatorIndex = remaining.indexOf('&');

        currentState = separatorIndex === -1 ? remaining : remaining.slice(0, separatorIndex);
      }

      path += `&state=${currentState}`

      this.tokens.forEach((token) => {
        const param = validTokenKeys.find((t) => {
          return t.key === token.key;
        }).param;

        path += `&${token.key}_${param}=${encodeURIComponent(token.value)}`;
      });

      if (this.searchToken) {
        path += '&search=' + encodeURIComponent(this.searchToken);
      }

      window.location = path;
    }
  }

  global.FilteredSearchManager = FilteredSearchManager;
})(window.gl || (window.gl = {}));
