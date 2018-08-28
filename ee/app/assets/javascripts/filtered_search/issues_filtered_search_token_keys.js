import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';
import {
  tokenKeys,
  alternativeTokenKeys,
  conditions,
} from '~/filtered_search/issues_filtered_search_token_keys';

const weightTokenKey = {
  key: 'weight',
  type: 'string',
  param: '',
  symbol: '',
  icon: 'balance-scale',
  tag: 'number',
};

const weightConditions = [
  {
    url: 'weight=None',
    tokenKey: 'weight',
    value: 'None',
  },
  {
    url: 'weight=Any',
    tokenKey: 'weight',
    value: 'Any',
  },
];

const IssuesFilteredSearchTokenKeysEE = new FilteredSearchTokenKeys(
  [...tokenKeys, weightTokenKey],
  alternativeTokenKeys,
  [...conditions, ...weightConditions],
);

// cannot be an arrow function because it needs FilteredSearchTokenKeys instance
IssuesFilteredSearchTokenKeysEE.init = function init(availableFeatures) {
  // Enable multiple assignees when available
  if (availableFeatures && availableFeatures.multipleAssignees) {
    const assigneeTokenKey = this.tokenKeys.find(tk => tk.key === 'assignee');
    assigneeTokenKey.type = 'array';
    assigneeTokenKey.param = 'username[]';
  }
};

export default IssuesFilteredSearchTokenKeysEE;
