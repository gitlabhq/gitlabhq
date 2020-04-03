const createState = (initialState = {}) => ({
  isLoadingContent: false,
  isContentLoaded: false,

  content: '',
  ...initialState,
});

export default createState;
