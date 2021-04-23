import { OPERATOR_IS, OPERATOR_IS_NOT } from '~/issues_list/constants';

export const locationSearch = [
  '?search=find+issues',
  'author_username=homer',
  'not[author_username]=marge',
  'assignee_username[]=bart',
  'not[assignee_username][]=lisa',
  'label_name[]=cartoon',
  'label_name[]=tv',
  'not[label_name][]=live action',
  'not[label_name][]=drama',
].join('&');

export const filteredTokens = [
  { type: 'author_username', value: { data: 'homer', operator: OPERATOR_IS } },
  { type: 'author_username', value: { data: 'marge', operator: OPERATOR_IS_NOT } },
  { type: 'assignee_username', value: { data: 'bart', operator: OPERATOR_IS } },
  { type: 'assignee_username', value: { data: 'lisa', operator: OPERATOR_IS_NOT } },
  { type: 'labels', value: { data: 'cartoon', operator: OPERATOR_IS } },
  { type: 'labels', value: { data: 'tv', operator: OPERATOR_IS } },
  { type: 'labels', value: { data: 'live action', operator: OPERATOR_IS_NOT } },
  { type: 'labels', value: { data: 'drama', operator: OPERATOR_IS_NOT } },
  { type: 'filtered-search-term', value: { data: 'find' } },
  { type: 'filtered-search-term', value: { data: 'issues' } },
];
