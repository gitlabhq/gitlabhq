import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';

const weightTokenKey = {
  key: 'weight',
  type: 'string',
  param: '',
  symbol: '',
  icon: 'balance-scale',
  tag: 'number',
};

const weightConditions = [{
  url: 'weight=None',
  tokenKey: 'weight',
  value: 'None',
}, {
  url: 'weight=Any',
  tokenKey: 'weight',
  value: 'Any',
}];

const alternativeTokenKeys = [{
  key: 'assignee',
  type: 'string',
  param: 'username',
  symbol: '@',
}];

export default class FilteredSearchTokenKeysIssues extends FilteredSearchTokenKeys {
  static init(availableFeatures) {
    this.availableFeatures = availableFeatures;
  }

  static get() {
    const tokenKeys = Array.from(super.get());

    // Enable multiple assignees when available
    if (this.availableFeatures && this.availableFeatures.multipleAssignees) {
      const assigneeTokenKey = tokenKeys.find(tk => tk.key === 'assignee');
      assigneeTokenKey.type = 'array';
      assigneeTokenKey.param = 'username[]';
    }

    tokenKeys.push(weightTokenKey);
    return tokenKeys;
  }

  static getKeys() {
    const tokenKeys = FilteredSearchTokenKeysIssues.get();
    return tokenKeys.map(i => i.key);
  }

  static getAlternatives() {
    return alternativeTokenKeys.concat(super.getAlternatives());
  }

  static getConditions() {
    const conditions = super.getConditions();
    return conditions.concat(weightConditions);
  }

  static searchByKey(key) {
    const tokenKeys = FilteredSearchTokenKeysIssues.get();
    return tokenKeys.find(tokenKey => tokenKey.key === key) || null;
  }

  static searchBySymbol(symbol) {
    const tokenKeys = FilteredSearchTokenKeysIssues.get();
    return tokenKeys.find(tokenKey => tokenKey.symbol === symbol) || null;
  }

  static searchByKeyParam(keyParam) {
    const tokenKeys = FilteredSearchTokenKeysIssues.get();
    const alternatives = FilteredSearchTokenKeysIssues.getAlternatives();
    const tokenKeysWithAlternative = tokenKeys.concat(alternatives);

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
    const conditions = FilteredSearchTokenKeysIssues.getConditions();
    return conditions.find(condition => condition.url === url) || null;
  }

  static searchByConditionKeyValue(key, value) {
    const conditions = FilteredSearchTokenKeysIssues.getConditions();
    return conditions
      .find(condition => condition.tokenKey === key && condition.value === value) || null;
  }
}
