const tokenKeys = [{
  key: 'author',
  type: 'string',
  param: 'username',
  symbol: '@',
  icon: 'pencil',
  tag: '@author',
}, {
  key: 'assignee',
  type: 'string',
  param: 'username',
  symbol: '@',
  icon: 'user',
  tag: '@assignee',
}, {
  key: 'milestone',
  type: 'string',
  param: 'title',
  symbol: '%',
  icon: 'clock-o',
  tag: '%milestone',
}, {
  key: 'label',
  type: 'array',
  param: 'name[]',
  symbol: '~',
  icon: 'tag',
  tag: '~label',
}];

if (gon.current_user_id) {
  // Appending tokenkeys only logged-in
  tokenKeys.push({
    key: 'my-reaction',
    type: 'string',
    param: 'emoji',
    symbol: '',
    icon: 'thumbs-up',
    tag: 'emoji',
  });
}

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

export default class FilteredSearchTokenKeys {
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
