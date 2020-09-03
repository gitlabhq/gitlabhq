/**
 * Strips enclosing quotations from a string if it has one.
 *
 * @param {String} value String to strip quotes from
 *
 * @returns {String} String without any enclosure
 */
export const stripQuotes = value => value.replace(/^('|")(.*)('|")$/, '$2');

/**
 * This method removes duplicate tokens from tokens array.
 *
 * @param {Array} tokens Array of tokens as defined by `GlFilteredSearch`
 *
 * @returns {Array} Unique array of tokens
 */
export const uniqueTokens = tokens => {
  const knownTokens = [];
  return tokens.reduce((uniques, token) => {
    if (typeof token === 'object' && token.type !== 'filtered-search-term') {
      const tokenString = `${token.type}${token.value.operator}${token.value.data}`;
      if (!knownTokens.includes(tokenString)) {
        uniques.push(token);
        knownTokens.push(tokenString);
      }
    } else {
      uniques.push(token);
    }
    return uniques;
  }, []);
};
