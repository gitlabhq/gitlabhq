export default ({ dropdownType = '' } = {}) => ({
  namespace: '',
  dropdownType,
  storageKey: '',
  searchQuery: '',
  isLoadingItems: false,
  isFetchFailed: false,
  isItemsListEditable: false,
  isItemRemovalFailed: false,
  items: [],
});
