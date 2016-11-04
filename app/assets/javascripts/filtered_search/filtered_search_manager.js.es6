((global) => {
  const TOKEN_TYPE_STRING = 'string';
  const TOKEN_TYPE_ARRAY = 'array';

  const validTokenKeys = [{
    key: 'author',
    type: 'string',
  },{
    key: 'assignee',
    type: 'string'
  },{
    key: 'milestone',
    type: 'string'
  },{
    key: 'label',
    type: 'array'
  },];

  class FilteredSearchManager {
    constructor() {
      this.bindEvents();
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
            return v.name === tokenKey;
          })[0];

          if (match) {
              this.tokens.push = {
                key: match.key,
                value: tokenValue,
              };
          }
        } else {
          searchTerms += i + ' ';
        }
      }, this);

      this.searchToken = searchTerms.trim();
      this.printTokens();
    }

    printTokens() {
      console.log(this.tokens);
      console.log(this.searchToken);
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

      this.tokens.foreach((token) => {

      });

      if (this.searchToken) {
        path += '&search=' + this.searchToken;
      }

      window.location = path;
    }
  }

  global.FilteredSearchManager = FilteredSearchManager;
})(window.gl || (window.gl = {}));