export const hasSearchQuery = state => state.searchQuery !== '';

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
