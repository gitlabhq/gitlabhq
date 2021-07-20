export default () => ({
  jobEndpoint: null,
  traceEndpoint: null,

  // sidebar
  isSidebarOpen: true,

  isLoading: false,
  hasError: false,
  job: {},

  // scroll buttons state
  isScrollBottomDisabled: true,
  isScrollTopDisabled: true,

  // Used to check if we should keep the automatic scroll
  isScrolledToBottomBeforeReceivingTrace: true,

  trace: [],
  isTraceComplete: false,
  traceSize: 0,
  isTraceSizeVisible: false,
  traceTimeout: 0,

  // used as a query parameter to fetch the trace
  traceState: null,

  // sidebar dropdown & list of jobs
  isLoadingJobs: false,
  selectedStage: '',
  stages: [],
  jobs: [],

  // to parse partial logs
  auxiliaryPartialTraceHelpers: {},
});
