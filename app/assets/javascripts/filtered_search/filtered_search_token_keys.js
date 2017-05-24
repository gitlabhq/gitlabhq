const tokenKeys = [{
  key: 'author',
  type: 'string',
  param: 'username',
  symbol: '@',
  icon: 'pencil',
}, {
  key: 'assignee',
  type: 'string',
  param: 'username',
  symbol: '@',
  icon: 'user',
}, {
  key: 'milestone',
  type: 'string',
  param: 'title',
  symbol: '%',
  icon: 'clock-o',
}, {
  key: 'label',
  type: 'array',
  param: 'name[]',
  symbol: '~',
  icon: 'tag',
}];

const alternativeTokenKeys = [{
  key: 'label',
  type: 'string',
  param: 'name',
  symbol: '~',
}];

const tokenKeysWithAlternative = tokenKeys.concat(alternativeTokenKeys);

const conditions = [{
  url: 'assignee_id=0',
  tokenKey: 'assignee',
  value: 'none',
}, {
  url: 'milestone_title=No+Milestone',
  tokenKey: 'milestone',
  value: 'none',
}, {
  url: 'milestone_title=%23upcoming',
  tokenKey: 'milestone',
  value: 'upcoming',
}, {
  url: 'milestone_title=%23started',
  tokenKey: 'milestone',
  value: 'started',
}, {
  url: 'label_name[]=No+Label',
  tokenKey: 'label',
  value: 'none',
}];

class FilteredSearchTokenKeys {
  static get() {
    return tokenKeys;
  }

  static getKeys() {
    return tokenKeys.map(i => i.key);
  }

  static getAlternatives() {
    return alternativeTokenKeys;
  }

  static getConditions() {
    return conditions;
  }

  static searchByKey(key) {
    return tokenKeys.find(tokenKey => tokenKey.key === key) || null;
  }

  static searchBySymbol(symbol) {
    return tokenKeys.find(tokenKey => tokenKey.symbol === symbol) || null;
  }

  static searchByKeyParam(keyParam) {
    return tokenKeysWithAlternative.find((tokenKey) => {
      let tokenKeyParam = tokenKey.key;

      if (tokenKey.param) {
        tokenKeyParam += `_${tokenKey.param}`;
      }

      return keyParam === tokenKeyParam;
    }) || null;
  }

  static searchByConditionUrl(url) {
    return conditions.find(condition => condition.url === url) || null;
  }

  static searchByConditionKeyValue(key, value) {
    return conditions
      .find(condition => condition.tokenKey === key && condition.value === value) || null;
  }
}

window.gl = window.gl || {};
gl.FilteredSearchTokenKeys = FilteredSearchTokenKeys;
