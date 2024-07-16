export default () => ({
  /**
   * Determine if the component is loading data from the API
   */
  isLoading: false,
  /**
   * Each object in `packages` has the following structure:
   * {
   *   id: String
   *   name: String,
   *   version: String,
   *   package_type: String // endpoint to request the list
   * }
   */
  packages: [],
  /**
   * Pagination object has the following structure:
   * {
   *  perPage: Number,
   *  page: Number
   *  total: Number
   * }
   */
  pagination: {},
  /**
   * Sorting object has the following structure:
   * {
   *  sort: String,
   *  orderBy: String
   * }
   */
  sorting: {
    sort: 'desc',
    orderBy: 'created_at',
  },
  /**
   * The search query that is used to filter packages by name
   */
  filter: [],
  /**
   * The selected TAB of the package types tabs
   */
});
