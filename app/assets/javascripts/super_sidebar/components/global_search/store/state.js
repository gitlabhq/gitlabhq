const createState = ({ searchContext, search }) => ({
  searchContext,
  search,
  autocompleteOptions: [],
  autocompleteError: false,
  loading: false,
  commandChar: '',
});
export default createState;
