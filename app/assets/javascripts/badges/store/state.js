export default (initialState) => ({
  apiEndpointUrl: null,
  badgeInAddForm: {},
  badgeInEditForm: {},
  badgeInModal: null,
  badges: [],
  pagination: {},
  renderedBadge: null,
  isEditing: false,
  isLoading: false,
  isRendering: false,
  isSaving: false,
  ...initialState,
});
