import { PACKAGE_REGISTRY_TABS } from '../constants';

export default () => ({
  /**
   * Determine if the component is loading data from the API
   */
  isLoading: false,
  /**
   * configuration object, set once at store creation with the following structure
   * {
   *  resourceId: String,
   *  pageType: String,
   *  emptyListIllustration: String,
   *  emptyListHelpUrl: String,
   *  comingSoon: { projectPath: String, suggestedContributions : String } | null;
   * }
   */
  config: {},
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
  filterQuery: '',
  /**
   * The selected TAB of the package types tabs
   */
  selectedType: PACKAGE_REGISTRY_TABS[0],
});
