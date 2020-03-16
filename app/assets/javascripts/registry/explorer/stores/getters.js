// eslint-disable-next-line import/prefer-default-export
export const tags = state => {
  // to show the loader inside the table we need to pass an empty array to gl-table whenever the table is loading
  // this is to take in account isLoading = true and state.tags =[1,2,3] during pagination and delete
  return state.isLoading ? [] : state.tags;
};
