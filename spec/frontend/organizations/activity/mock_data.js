import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import { CONTRIBUTION_TYPE_FILTER_TYPE } from '~/organizations/activity/filters';

export const MOCK_ALL_EVENT = 'all';

export const MOCK_EVENT_TYPES = [
  {
    title: 'Push events',
    value: 'push',
  },
  {
    title: 'Merge events',
    value: 'merged',
  },
  {
    title: 'Issue events',
    value: 'issue',
  },
  {
    title: 'Comments',
    value: 'comments',
  },
  {
    title: 'Wiki',
    value: 'wiki',
  },
  {
    title: 'Designs',
    value: 'designs',
  },
  {
    title: 'Team',
    value: 'team',
  },
];

export const MOCK_CONTRIBUTION_TYPE_VALUE = { data: 'comments', operator: '=' };

export const MOCK_SEARCH_TOKEN = { type: FILTERED_SEARCH_TERM, value: '' };
export const MOCK_EMPTY_CONTRIBUTION_TYPE = { type: CONTRIBUTION_TYPE_FILTER_TYPE, value: '' };
export const MOCK_SELECTED_CONTRIBUTION_TYPE = {
  type: CONTRIBUTION_TYPE_FILTER_TYPE,
  value: MOCK_CONTRIBUTION_TYPE_VALUE,
};
