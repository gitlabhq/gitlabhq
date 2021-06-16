export default () => ({
  // Initial Data
  labels: [],
  selectedLabels: [],
  labelsListTitle: '',
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
