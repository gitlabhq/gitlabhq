const createRefTypeState = () => ({
  list: [],
  totalCount: 0,
  error: null,
});

export default () => ({
  enabledRefTypes: [],
  projectId: null,

  query: '',
  matches: {
    branches: createRefTypeState(),
    tags: createRefTypeState(),
    commits: createRefTypeState(),
  },
  selectedRef: null,
  requestCount: 0,
});
