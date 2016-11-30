/* eslint-disable no-param-reassign */
((global) => {
  class FilteredSearchTokenizer {
    // TODO: Remove when going to pro
    static printTokens(tokens, searchToken, lastToken) {
      // console.log('tokens:');
      // tokens.forEach(token => console.log(token));
      // console.log(`search: ${searchToken}`);
      // console.log('last token:');
      // console.log(lastToken);
    }

    static parseToken(input) {
      const colonIndex = input.indexOf(':');
      let tokenKey;
      let tokenValue;
      let tokenSymbol;

      if (colonIndex !== -1) {
        tokenKey = input.slice(0, colonIndex).toLowerCase();
        tokenValue = input.slice(colonIndex + 1);
        tokenSymbol = tokenValue[0];
      }

      return {
        tokenKey,
        tokenValue,
        tokenSymbol,
      }
    }

    static processTokens(input) {
      let tokens = [];
      let searchToken = '';
      let lastToken = '';
      const validTokenKeys = gl.FilteredSearchTokenKeys.get();

      const inputs = input.split(' ');
      let searchTerms = '';
      let lastQuotation = '';
      let incompleteToken = false;

      inputs.forEach((i) => {
        if (incompleteToken) {
          const prevToken = tokens.last();
          prevToken.value += ` ${i}`;

          // Remove last quotation
          const lastQuotationRegex = new RegExp(lastQuotation, 'g');
          prevToken.value = prevToken.value.replace(lastQuotationRegex, '');
          tokens[tokens.length - 1] = prevToken;

          // Check to see if this quotation completes the token value
          if (i.indexOf(lastQuotation)) {
            lastToken = tokens.last();
            incompleteToken = !incompleteToken;
          }

          return;
        }

        const colonIndex = i.indexOf(':');

        if (colonIndex !== -1) {
          const { tokenKey, tokenValue, tokenSymbol } = gl.FilteredSearchTokenizer.parseToken(i);

          const keyMatch = validTokenKeys.filter(v => v.key === tokenKey)[0];
          const symbolMatch = validTokenKeys.filter(v => v.symbol === tokenSymbol)[0];

          const doubleQuoteIndex = tokenValue.indexOf('"');
          const singleQuoteIndex = tokenValue.indexOf('\'');

          const doubleQuoteExist = doubleQuoteIndex !== -1;
          const singleQuoteExist = singleQuoteIndex !== -1;

          if ((doubleQuoteExist && !singleQuoteExist) ||
            (doubleQuoteExist && singleQuoteExist && doubleQuoteIndex < singleQuoteIndex)) {
            // " is found and is in front of ' (if any)
            lastQuotation = '"';
            incompleteToken = true;
          } else if ((singleQuoteExist && !doubleQuoteExist) ||
           (doubleQuoteExist && singleQuoteExist && singleQuoteIndex < doubleQuoteIndex)) {
            // ' is found and is in front of " (if any)
            lastQuotation = '\'';
            incompleteToken = true;
          }

          if (keyMatch && tokenValue.length > 0) {
            tokens.push({
              key: keyMatch.key,
              value: tokenValue,
              wildcard: symbolMatch ? false : true,
            });
            lastToken = tokens.last();

            return;
          }
        }

        // Add space for next term
        searchTerms += `${i} `;
        lastToken = i;
      }, this);

      searchToken = searchTerms.trim();

      // TODO: Remove when going to PRO
      gl.FilteredSearchTokenizer.printTokens(tokens, searchToken, lastToken);

      return {
        tokens,
        searchToken,
        lastToken,
      };
    }
  }

  global.FilteredSearchTokenizer = FilteredSearchTokenizer;
})(window.gl || (window.gl = {}));
