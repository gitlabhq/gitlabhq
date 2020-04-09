const createState = (initialState = {}) => ({
  projectId: null,
  sourcePath: null,

  isLoadingContent: false,
  isSavingChanges: false,

  originalContent: '',
  content: '',
  title: '',

  ...initialState,
});

export default createState;
