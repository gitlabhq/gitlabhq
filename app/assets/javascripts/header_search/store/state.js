const createState = ({ searchPath, issuesPath, mrPath, autocompletePath, searchContext }) => ({
  searchPath,
  issuesPath,
  mrPath,
  autocompletePath,
  searchContext,
  search: '',
  autocompleteOptions: [],
  loading: false,
});
export default createState;
