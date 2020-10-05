export default ({
  projectId,
  projectPath,
  documentationPath,
  illustrationPath,
  newReleasePath = '',
}) => ({
  projectId,
  projectPath,
  documentationPath,
  illustrationPath,
  newReleasePath,

  isLoading: false,
  hasError: false,
  releases: [],
  restPageInfo: {},
  graphQlPageInfo: {},
});
