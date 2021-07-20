export default () => ({
  // Initial Data
  labels: [],
  labelsFetched: false,
  selectedLabels: [],
  labelsListTitle: '',
  labelsCreateTitle: '',
  footerCreateLabelTitle: '',
  footerManageLabelTitle: '',
  dropdownButtonText: '',

  // Paths
  namespace: '',
  labelsFetchPath: '',
  labelsFilterBasePath: '',

  // UI Flags
  variant: '',
  allowLabelRemove: false,
  allowLabelCreate: false,
  allowLabelEdit: false,
  allowScopedLabels: false,
  allowMultiselect: false,
  showDropdownButton: false,
  showDropdownContents: false,
  showDropdownContentsCreateView: false,
  labelsFetchInProgress: false,
  labelCreateInProgress: false,
  selectedLabelsUpdated: false,
});
