import {
  PAGINATION_SORT_FIELD_DURATION,
  PAGINATION_SORT_DIRECTION_DESC,
} from '~/analytics/cycle_analytics/constants';

export default () => ({
  id: null,
  features: {},
  groupPath: {},
  namespace: {
    name: null,
    restApiRequestPath: null,
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
    sort: PAGINATION_SORT_FIELD_DURATION,
    direction: PAGINATION_SORT_DIRECTION_DESC,
  },
  predefinedDateRange: null,
});
