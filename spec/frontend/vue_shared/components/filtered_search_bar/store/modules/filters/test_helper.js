export function getFilterParams(tokens, options = {}) {
  const { key = 'value', operator = '=', prop = 'title' } = options;
  return tokens.map((token) => {
    return { [key]: token[prop], operator };
  });
}

export function getFilterValues(tokens, options = {}) {
  const { prop = 'title' } = options;
  return tokens.map((token) => token[prop]);
}
