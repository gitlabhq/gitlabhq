export default () => ({
  paths: {
    head: null,
    base: null,
    diffEndpoint: null,
  },

  isLoading: false,
  hasError: false,

  newIssues: [],
  resolvedIssues: [],
  allIssues: [],
  baseReportOutofDate: false,
  hasBaseReport: false,
});
