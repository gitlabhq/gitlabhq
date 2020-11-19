import { DESCENDING_ORDER, RELEASED_AT } from '../../../constants';

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
  sorting: {
    sort: DESCENDING_ORDER,
    orderBy: RELEASED_AT,
  },
});
