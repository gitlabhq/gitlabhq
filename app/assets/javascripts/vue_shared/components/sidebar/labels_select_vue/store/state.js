export default () => ({
  // Initial Data
  labels: [],
  selectedLabels: [],
  labelsListTitle: '',
  labelsCreateTitle: '',
  footerCreateLabelTitle: '',
  footerManageLabelTitle: '',

  // Paths
  namespace: '',
  labelsFetchPath: '',
  labelsFilterBasePath: '',

  // UI Flags
  allowLabelCreate: false,
  allowLabelEdit: false,
  allowScopedLabels: false,
  dropdownOnly: false,
  showDropdownButton: false,
  showDropdownContents: false,
  showDropdownContentsCreateView: false,
  labelsFetchInProgress: false,
  labelCreateInProgress: false,
  selectedLabelsUpdated: false,
});
