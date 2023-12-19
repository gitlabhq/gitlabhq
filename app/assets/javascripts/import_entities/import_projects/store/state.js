export default () => ({
  provider: '',
  repositories: [],
  customImportTargets: {},
  isLoadingRepos: false,
  ciCdOnly: false,
  filter: {},
  pageInfo: {
    page: 0,
    startCursor: null,
    endCursor: null,
    hasNextPage: false,
  },
});
