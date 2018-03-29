export default () => ({
  summaryCounts: {
    added: 0,
    fixed: 0,
  },

  blobPath: {
    head: null,
    base: null,
  },

  sast: {
    paths: {
      head: null,
      base: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
    resolvedIssues: [],
    allIssues: [],
  },
  sastContainer: {
    paths: {
      head: null,
      base: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
    resolvedIssues: [],
  },
  dast: {
    paths: {
      head: null,
      base: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
    resolvedIssues: [],
  },

  dependencyScanning: {
    paths: {
      head: null,
      base: null,
    },

    isLoading: false,
    hasError: false,

    newIssues: [],
    resolvedIssues: [],
    allIssues: [],
  },
});
