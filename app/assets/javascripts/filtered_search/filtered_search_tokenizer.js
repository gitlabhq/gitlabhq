import './filtered_search_token_keys';

export default class FilteredSearchTokenizer {
  static processTokens(input, allowedKeys) {
    // Regex extracts `(token):(symbol)(value)`
    // Values that start with a double quote must end in a double quote (same for single)
    const tokenRegex = new RegExp(`(${allowedKeys.join('|')}):([~%@]?)(?:('[^']*'{0,1})|("[^"]*"{0,1})|(\\S+))`, 'g');
    const tokens = [];
    const tokenIndexes = []; // stores key+value for simple search
    let lastToken = null;
    const searchToken = input.replace(tokenRegex, (match, key, symbol, v1, v2, v3) => {
      let tokenValue = v1 || v2 || v3;
      let tokenSymbol = symbol;
      let tokenIndex = '';

      if (tokenValue === '~' || tokenValue === '%' || tokenValue === '@') {
        tokenSymbol = tokenValue;
        tokenValue = '';
      }

      tokenIndex = `${key}:${tokenValue}`;

      // Prevent adding duplicates
      if (tokenIndexes.indexOf(tokenIndex) === -1) {
        tokenIndexes.push(tokenIndex);

        tokens.push({
          key,
          value: tokenValue || '',
          symbol: tokenSymbol || '',
        });
      }

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
