export default {
  endpoint: null,

  permissions: {
    canCreatePipeline: false,
    canResetCache: false,
  },

  paths: {
    helpPagePath: null,
    newPipelinePath: null,
    ciLintPath: null,
    emptyStateSvgPath: null,
    errorStateSvgPath: null,
    autoDevopsPath: null,
    resetCachePath: null,
  },

  viewType: 'main', // 'main || child'

  hasCI: false,

  isLoading: false,
  hasError: false,
  isMakingRequest: false,
  updateGraphDropdown: false,
  hasMadeRequest: false,

  scope: 'all',
  page: '1',
  requestData: {},

  pipelines: [],
  count: {},
  pagination: {},
};
