import {
  PAGINATION_SORT_FIELD_END_EVENT,
  PAGINATION_SORT_DIRECTION_DESC,
} from '~/analytics/cycle_analytics/constants';

export default () => ({
  id: null,
  features: {},
  groupPath: {},
  namespace: {
    name: null,
    fullPath: null,
  },
  createdAfter: null,
  createdBefore: null,
  stages: [],
  analytics: [],
  valueStreams: [],
  selectedValueStream: {},
  selectedStage: {},
  selectedStageEvents: [],
  selectedStageError: '',
  medians: {},
  stageCounts: {},
  hasNoAccessError: false,
  isLoading: false,
  isLoadingStage: false,
  isEmptyStage: false,
  pagination: {
    page: null,
    hasNextPage: false,
    sort: PAGINATION_SORT_FIELD_END_EVENT,
    direction: PAGINATION_SORT_DIRECTION_DESC,
  },
});
