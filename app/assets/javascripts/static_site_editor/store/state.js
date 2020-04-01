const createState = (initialState = {}) => ({
  content: '',
  ...initialState,
});

export default createState;
