import { __ } from '~/locale';

export default () => ({
  endpoint: null,
  projectId: null,
  isGroup: null,
  maskableRegex: null,
  isLoading: false,
  isDeleting: false,
  variable: {
    variable_type: __('Variable'),
    key: '',
    secret_value: '',
    protected: false,
    masked: false,
    environment_scope: __('All environments'),
  },
  variables: null,
  valuesHidden: true,
  error: null,
  environments: [],
  typeOptions: [__('Variable'), __('File')],
  variableBeingEdited: null,
});
