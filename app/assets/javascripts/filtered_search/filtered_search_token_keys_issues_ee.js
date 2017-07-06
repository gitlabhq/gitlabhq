import './filtered_search_token_keys';

const weightTokenKey = {
  key: 'weight',
  type: 'string',
  param: '',
  symbol: '',
  icon: 'balance-scale',
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

class FilteredSearchTokenKeysIssuesEE extends gl.FilteredSearchTokenKeys {
  static init(availableFeatures) {
    this.availableFeatures = availableFeatures;
  }

  static get() {
    const tokenKeys = Array.from(super.get());

    // Enable multiple assignees when available
    if (this.availableFeatures && this.availableFeatures.multipleAssignees) {
      const assigneeTokenKey = tokenKeys.find(tk => tk.key === 'assignee');
      assigneeTokenKey.type = 'array';
    }

    tokenKeys.push(weightTokenKey);
    return tokenKeys;
  }

  static getKeys() {
    const tokenKeys = FilteredSearchTokenKeysIssuesEE.get();
    return tokenKeys.map(i => i.key);
  }

  static getAlternatives() {
    return super.getAlternatives();
  }

  static getConditions() {
    const conditions = super.getConditions();
    return conditions.concat(weightConditions);
  }

  static searchByKey(key) {
    const tokenKeys = FilteredSearchTokenKeysIssuesEE.get();
    return tokenKeys.find(tokenKey => tokenKey.key === key) || null;
  }

  static searchBySymbol(symbol) {
    const tokenKeys = FilteredSearchTokenKeysIssuesEE.get();
    return tokenKeys.find(tokenKey => tokenKey.symbol === symbol) || null;
  }

  static searchByKeyParam(keyParam) {
    const tokenKeys = FilteredSearchTokenKeysIssuesEE.get();
    const alternativeTokenKeys = FilteredSearchTokenKeysIssuesEE.getAlternatives();
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
    const conditions = FilteredSearchTokenKeysIssuesEE.getConditions();
    return conditions.find(condition => condition.url === url) || null;
  }

  static searchByConditionKeyValue(key, value) {
    const conditions = FilteredSearchTokenKeysIssuesEE.getConditions();
    return conditions
      .find(condition => condition.tokenKey === key && condition.value === value) || null;
  }
}

window.gl = window.gl || {};
gl.FilteredSearchTokenKeysIssuesEE = FilteredSearchTokenKeysIssuesEE;
