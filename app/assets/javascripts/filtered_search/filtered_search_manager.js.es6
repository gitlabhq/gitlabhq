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
    param: 'name%5B%5D',
  },];

  class FilteredSearchManager {
    constructor() {
      this.bindEvents();
      this.loadSearchParamsFromURL();
      this.clearTokens();
    }

    bindEvents() {
      const input = document.querySelector('.filtered-search');

      input.addEventListener('input', this.tokenize.bind(this));
      input.addEventListener('keydown', this.checkForEnter.bind(this));
    }

    clearTokens() {
      this.tokens = [];
      this.searchToken = '';
    }

    loadSearchParamsFromURL() {
      const params = window.location.search.split('&');
      let inputValue = '';

      params.forEach((p) => {
        const split = p.split('=');
        const key = split[0];
        const value = split[1];

        const match = validTokenKeys.find((t) => {
          return key === `${t.key}_${t.param}`;
        });

        if (match) {
          const sanitizedKey = key.slice(0, key.indexOf('_'));
          inputValue += `${sanitizedKey}:${value} `;
        } else if (!match && key === 'search') {
          inputValue += `${value} `;
        }
      });

      // Trim the last space value
      document.querySelector('.filtered-search').value = inputValue.trim();
    }

    tokenize(event) {
      // Re-calculate tokens
      this.clearTokens();

      // TODO: Current implementation does not support token values that have valid spaces in them
      // Example/ label:community contribution
      const input = event.target.value;
      const inputs = input.split(' ');
      let searchTerms = '';

      inputs.forEach((i) => {
        const colonIndex = i.indexOf(':');

        // Check if text is a token
        if (colonIndex !== -1) {
          const tokenKey = i.slice(0, colonIndex).toLowerCase();
          const tokenValue = i.slice(colonIndex + 1);

          const match = validTokenKeys.filter((v) => {
            return v.key === tokenKey;
          })[0];

          if (match && tokenValue.length > 0) {
            this.tokens.push({
              key: match.key,
              value: tokenValue,
            });
          }
        } else {
          searchTerms += i + ' ';
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
      let path = '?scope=all&state=opened&utf8=✓';


      this.tokens.forEach((token) => {
        const param = validTokenKeys.find((t) => {
          return t.key === token.key;
        }).param;

        path += `&${token.key}_${param}=${token.value}`;
      });

      if (this.searchToken) {
        path += '&search=' + this.searchToken;
      }

      window.location = path;
    }
  }

  global.FilteredSearchManager = FilteredSearchManager;
})(window.gl || (window.gl = {}));