export default () => ({
  projectId: null,

  query: '',
  matches: {
    branches: {
      list: [],
      totalCount: 0,
      error: null,
    },
    tags: {
      list: [],
      totalCount: 0,
      error: null,
    },
    commits: {
      list: [],
      totalCount: 0,
      error: null,
    },
  },
  selectedRef: null,
  requestCount: 0,
});
