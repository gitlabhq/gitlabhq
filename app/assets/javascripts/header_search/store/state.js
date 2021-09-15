const createState = ({ searchPath, issuesPath, mrPath, searchContext }) => ({
  searchPath,
  issuesPath,
  mrPath,
  searchContext,
  search: '',
});
export default createState;
