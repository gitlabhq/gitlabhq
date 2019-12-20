export const isLoading = state => state.isLoading;
export const repos = state => state.repos;
export const isDeleteDisabled = state => state.isDeleteDisabled;

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
