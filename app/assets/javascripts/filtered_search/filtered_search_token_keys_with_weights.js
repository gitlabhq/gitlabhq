require('./filtered_search_token_keys');

const weightTokenKey = {
  key: 'weight',
  type: 'string',
  param: '',
  symbol: '',
};

const weightConditions = [{
  url: 'weight=No+Weight',
  tokenKey: 'weight',
  value: 'none',
}, {
  url: 'weight=Any+Weight',
  tokenKey: 'weight',
  value: 'any',
}];

class FilteredSearchTokenKeysWithWeights extends gl.FilteredSearchTokenKeys {
  static get() {
    const tokenKeys = super.get();
    tokenKeys.push(weightTokenKey);
    return tokenKeys;
  }

  static getAlternatives() {
    return super.getAlternatives();
  }

  static getConditions() {
    const conditions = super.getConditions();
    return conditions.concat(weightConditions);
  }

  static searchByKey(key) {
    const tokenKeys = FilteredSearchTokenKeysWithWeights.get();
    return tokenKeys.find(tokenKey => tokenKey.key === key) || null;
  }

  static searchBySymbol(symbol) {
    const tokenKeys = FilteredSearchTokenKeysWithWeights.get();
    return tokenKeys.find(tokenKey => tokenKey.symbol === symbol) || null;
  }

  static searchByKeyParam(keyParam) {
    const tokenKeys = FilteredSearchTokenKeysWithWeights.get();
    const alternativeTokenKeys = FilteredSearchTokenKeysWithWeights.getAlternatives();
    const tokenKeysWithAlternative = tokenKeys.concat(alternativeTokenKeys);

    return tokenKeysWithAlternative.find((tokenKey) => {
      let tokenKeyParam = tokenKey.key;

      if (tokenKey.param) {
        tokenKeyParam += `_${tokenKey.param}`;
      }

      return keyParam === tokenKeyParam;
    }) || null;
  }

  static searchByConditionUrl(url) {
    const conditions = FilteredSearchTokenKeysWithWeights.getConditions();
    return conditions.find(condition => condition.url === url) || null;
  }

  static searchByConditionKeyValue(key, value) {
    const conditions = FilteredSearchTokenKeysWithWeights.getConditions();
    return conditions
      .find(condition => condition.tokenKey === key && condition.value === value) || null;
  }
}

window.gl = window.gl || {};
gl.FilteredSearchTokenKeysWithWeights = FilteredSearchTokenKeysWithWeights;
