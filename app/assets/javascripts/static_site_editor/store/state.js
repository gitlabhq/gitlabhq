const createState = (initialState = {}) => ({
  username: null,
  projectId: null,
  returnUrl: null,
  sourcePath: null,

  isLoadingContent: false,
  isSavingChanges: false,
  isSupportedContent: false,

  isContentLoaded: false,

  originalContent: '',
  content: '',
  title: '',

  savedContentMeta: null,

  ...initialState,
});

export default createState;
