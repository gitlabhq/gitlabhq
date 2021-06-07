import { DEFAULT_DAYS_TO_DISPLAY } from '../constants';

export default () => ({
  requestPath: '',
  startDate: DEFAULT_DAYS_TO_DISPLAY,
  stages: [],
  summary: [],
  analytics: [],
  stats: [],
  selectedStage: {},
  selectedStageEvents: [],
  selectedStageError: '',
  medians: {},
  hasError: false,
  isLoading: false,
  isLoadingStage: false,
  isEmptyStage: false,
});
