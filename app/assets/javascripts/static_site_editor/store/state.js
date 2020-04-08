const createState = (initialState = {}) => ({
  projectId: null,
  sourcePath: null,

  isLoadingContent: false,

  content: '',
  title: '',

  ...initialState,
});

export default createState;
