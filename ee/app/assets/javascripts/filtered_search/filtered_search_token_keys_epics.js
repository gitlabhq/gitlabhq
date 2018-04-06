const tokenKeys = [{
  key: 'author',
  type: 'string',
  param: 'username',
  symbol: '@',
  icon: 'pencil',
  tag: '@author',
}, {
  key: 'label',
  type: 'array',
  param: 'name[]',
  symbol: '~',
  icon: 'tag',
  tag: '~label',
}];

const alternativeTokenKeys = [{
  key: 'label',
  type: 'string',
  param: 'name',
  symbol: '~',
}];

const tokenKeysWithAlternative = tokenKeys.concat(alternativeTokenKeys);

const conditions = [{
  url: 'label_name[]=No+Label',
  tokenKey: 'label',
  value: 'none',
}];

export default class FilteredSearchTokenKeysEpics {
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

      // Replace hyphen with underscore to compare keyParam with tokenKeyParam
      // e.g. 'my-reaction' => 'my_reaction'
      tokenKeyParam = tokenKeyParam.replace('-', '_');

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
