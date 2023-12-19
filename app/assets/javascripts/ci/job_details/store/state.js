export default () => ({
  jobEndpoint: null,
  logEndpoint: null,
  testReportSummaryUrl: null,

  // sidebar
  isSidebarOpen: true,
  testSummary: {},
  testSummaryComplete: false,

  isLoading: false,
  hasError: false,
  job: {},

  // scroll buttons state
  isScrollBottomDisabled: true,
  isScrollTopDisabled: true,

  // fullscreen mode
  fullScreenAPIAvailable: false,
  fullScreenModeAvailable: false,
  fullScreenEnabled: false,
  fullScreenContainerSetUp: false,

  jobLog: [],
  jobLogSections: {},
  isJobLogComplete: false,
  jobLogSize: 0,
  isJobLogSizeVisible: false,
  jobLogTimeout: 0,

  // used as a query parameter to fetch the job log
  jobLogState: null,

  // sidebar dropdown & list of jobs
  isLoadingJobs: false,
  selectedStage: '',
  stages: [],
  jobs: [],
});
