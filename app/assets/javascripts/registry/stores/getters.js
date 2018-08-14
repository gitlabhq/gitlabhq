export const isLoading = state => state.isLoading;
export const repos = state => state.repos;

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
