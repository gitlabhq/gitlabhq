/* eslint-disable no-param-reassign */
((global) => {
  class FilteredSearchTokenizer {
    constructor(validTokenKeys) {
      this.validTokenKeys = validTokenKeys;
      this.resetTokens();
    }

    getTokens() {
      return this.tokens;
    }

    getSearchToken() {
      return this.searchToken;
    }

    resetTokens() {
      this.tokens = [];
      this.searchToken = '';
    }

    printTokens() {
      console.log('tokens:');
      this.tokens.forEach(token => console.log(token));
      console.log(`search: ${this.searchToken}`);
    }

    processTokens(input) {
      // Re-calculate tokens
      this.resetTokens();

      const inputs = input.split(' ');
      let searchTerms = '';
      let lastQuotation = '';
      let incompleteToken = false;

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
          const match = this.validTokenKeys.find(v => v.key === tokenKey);

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

            return;
          }
        }

        // Add space for next term
        searchTerms += `${i} `;
      }, this);

      this.searchToken = searchTerms.trim();
      this.printTokens();
    }
  }

  global.FilteredSearchTokenizer = FilteredSearchTokenizer;
})(window.gl || (window.gl = {}));
