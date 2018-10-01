export default () => ({
  jobEndpoint: null,
  traceEndpoint: null,

  // dropdown options
  stagesEndpoint: null,
  // list of jobs on sidebard
  stageJobsEndpoint: null,

  // job log
  isLoading: false,
  hasError: false,
  job: {},

  // trace
  isLoadingTrace: false,
  hasTraceError: false,

  trace: '',

  isTraceScrolledToBottom: false,
  hasBeenScrolled: false,

  isTraceComplete: false,
  traceSize: 0, // todo_fl: needs to be converted into human readable format in components
  isTraceSizeVisible: false,

  fetchingStatusFavicon: false,
  // used as a query parameter
  traceState: null,
  // used to check if we need to redirect the user - todo_fl:  check if actually needed
  traceStatus: null,

  // sidebar dropdown
  isLoadingStages: false,
  isLoadingJobs: false,
  selectedStage: null,
  stages: [],
  jobs: [],
});
