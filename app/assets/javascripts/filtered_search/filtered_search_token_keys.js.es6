(() => {
  const tokenKeys = [{
    key: 'author',
    type: 'string',
    param: 'username',
    symbol: '@',
  }, {
    key: 'assignee',
    type: 'string',
    param: 'username',
    symbol: '@',
  }, {
    key: 'milestone',
    type: 'string',
    param: 'title',
    symbol: '%',
  }, {
    key: 'label',
    type: 'array',
    param: 'name[]',
    symbol: '~',
  }];

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
    url: 'label_name[]=No+Label',
    tokenKey: 'label',
    value: 'none',
  }];

  class FilteredSearchTokenKeys {
    static get() {
      return tokenKeys;
    }

    static searchByKey(key) {
      return tokenKeys.find(tokenKey => tokenKey.key === key) || null;
    }

    static searchBySymbol(symbol) {
      return tokenKeys.find(tokenKey => tokenKey.symbol === symbol) || null;
    }

    static searchByKeyParam(keyParam) {
      return tokenKeys.find(tokenKey => keyParam === `${tokenKey.key}_${tokenKey.param}`) || null;
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
})();
