require('./filtered_search_token_keys');

(() => {
  class FilteredSearchTokenizer {
    static processTokens(input) {
      const allowedKeys = gl.FilteredSearchTokenKeys.get().map(i => i.key);
      // Regex extracts `(token):(symbol)(value)`
      // Values that start with a double quote must end in a double quote (same for single)
      const tokenRegex = new RegExp(`(${allowedKeys.join('|')}):([~%@]?)(?:('[^']*'{0,1})|("[^"]*"{0,1})|(\\S+))`, 'g');
      const tokens = [];
      let lastToken = null;
      const searchToken = input.replace(tokenRegex, (match, key, symbol, v1, v2, v3) => {
        let tokenValue = v1 || v2 || v3;
        let tokenSymbol = symbol;

        if (tokenValue === '~' || tokenValue === '%' || tokenValue === '@') {
          tokenSymbol = tokenValue;
          tokenValue = '';
        }

        tokens.push({
          key,
          value: tokenValue || '',
          symbol: tokenSymbol || '',
        });
        return '';
      }).replace(/\s{2,}/g, ' ').trim() || '';

      if (tokens.length > 0) {
        const last = tokens[tokens.length - 1];
        const lastString = `${last.key}:${last.symbol}${last.value}`;
        lastToken = input.lastIndexOf(lastString) ===
          input.length - lastString.length ? last : searchToken;
      } else {
        lastToken = searchToken;
      }

      return {
        tokens,
        lastToken,
        searchToken,
      };
    }
  }

  window.gl = window.gl || {};
  gl.FilteredSearchTokenizer = FilteredSearchTokenizer;
})();
