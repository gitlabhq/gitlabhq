export default ({ dropdownType = '' } = {}) => ({
  namespace: '',
  dropdownType,
  storageKey: '',
  searchQuery: '',
  isLoadingItems: false,
  isFetchFailed: false,
  items: [],
});
