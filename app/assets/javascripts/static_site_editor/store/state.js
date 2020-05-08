const createState = (initialState = {}) => ({
  username: null,
  projectId: null,
  returnUrl: null,
  sourcePath: null,

  isLoadingContent: false,
  isSavingChanges: false,

  isContentLoaded: false,

  originalContent: '',
  content: '',
  title: '',

  submitChangesError: '',
  savedContentMeta: null,

  ...initialState,
});

export default createState;
