(() => {
  class FilteredSearchTokenizer {
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

    static getLastTokenObject(input) {
      const token = FilteredSearchTokenizer.getLastToken(input);
      const colonIndex = token.indexOf(':');

      const key = colonIndex !== -1 ? token.slice(0, colonIndex) : '';
      const value = colonIndex !== -1 ? token.slice(colonIndex) : token;

      return {
        key,
        value,
      }
    }

    static getLastToken(input) {
      let completeToken = false;
      let completeQuotation = true;
      let lastQuotation = '';
      let i = input.length;

      const doubleQuote = '"';
      const singleQuote = '\'';
      while(!completeToken && i >= 0) {
        const isDoubleQuote = input[i] === doubleQuote;
        const isSingleQuote = input[i] === singleQuote;

        // If the second quotation is found
        if ((lastQuotation === doubleQuote && input[i] === doubleQuote) ||
          (lastQuotation === singleQuote && input[i] === singleQuote)) {
          completeQuotation = true;
        }

        // Save the first quotation
        if ((input[i] === doubleQuote && lastQuotation === '') ||
          (input[i] === singleQuote && lastQuotation === '')) {
          lastQuotation = input[i];
          completeQuotation = false;
        }

        if (completeQuotation && input[i] === ' ') {
          completeToken = true;
        } else {
          i--;
        }
      }

      // Adjust by 1 because of empty space
      return input.slice(i + 1);
    }

    static processTokens(input) {
      let tokens = [];
      let searchToken = '';
      let lastToken = '';

      const inputs = input.split(' ');
      let searchTerms = '';
      let lastQuotation = '';
      let incompleteToken = false;

      // Iterate through each word (broken up by spaces)
      inputs.forEach((i) => {
        if (incompleteToken) {
          // Continue previous token as it had an escaped
          // quote in the beginning
          const prevToken = tokens.last();
          prevToken.value += ` ${i}`;

          // Remove last quotation from the value
          const lastQuotationRegex = new RegExp(lastQuotation, 'g');
          prevToken.value = prevToken.value.replace(lastQuotationRegex, '');
          tokens[tokens.length - 1] = prevToken;

          // Check to see if this quotation completes the token value
          if (i.indexOf(lastQuotation) !== -1) {
            lastToken = tokens.last();
            incompleteToken = !incompleteToken;
          }

          return;
        }

        const colonIndex = i.indexOf(':');

        if (colonIndex !== -1) {
          const { tokenKey, tokenValue, tokenSymbol } = gl.FilteredSearchTokenizer.parseToken(i);

          const keyMatch = gl.FilteredSearchTokenKeys.searchByKey(tokenKey);
          const symbolMatch = gl.FilteredSearchTokenKeys.searchBySymbol(tokenSymbol);

          const doubleQuoteOccurrences = tokenValue.split('"').length - 1;
          const singleQuoteOccurrences = tokenValue.split('\'').length - 1;

          const doubleQuoteIndex = tokenValue.indexOf('"');
          const singleQuoteIndex = tokenValue.indexOf('\'');

          const doubleQuoteExist = doubleQuoteIndex !== -1;
          const singleQuoteExist = singleQuoteIndex !== -1;

          const doubleQuoteExistOnly = doubleQuoteExist && !singleQuoteExist;
          const doubleQuoteIsBeforeSingleQuote = doubleQuoteExist && singleQuoteExist && doubleQuoteIndex < singleQuoteIndex;

          const singleQuoteExistOnly = singleQuoteExist && !doubleQuoteExist;
          const singleQuoteIsBeforeDoubleQuote = doubleQuoteExist && singleQuoteExist && singleQuoteIndex < doubleQuoteIndex;

          if ((doubleQuoteExistOnly || doubleQuoteIsBeforeSingleQuote) && doubleQuoteOccurrences % 2 !== 0) {
            // " is found and is in front of ' (if any)
            lastQuotation = '"';
            incompleteToken = true;
          } else if ((singleQuoteExistOnly || singleQuoteIsBeforeDoubleQuote) && singleQuoteOccurrences % 2 !== 0) {
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

      return {
        tokens,
        searchToken,
        lastToken,
      };
    }
  }

  window.gl = window.gl || {};
  gl.FilteredSearchTokenizer = FilteredSearchTokenizer;
})();
