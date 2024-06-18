import { __ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

export const VARIABLE_TYPE = 'env_var';
export const FILE_TYPE = 'file';
export const DEBOUNCE_REFS_SEARCH_MS = DEFAULT_DEBOUNCE_AND_THROTTLE_MS;
export const CONFIG_VARIABLES_TIMEOUT = 5000;
export const BRANCH_REF_TYPE = 'branch';
export const TAG_REF_TYPE = 'tag';

// must match pipeline/chain/validate/after_config.rb
export const CC_VALIDATION_REQUIRED_ERROR = __(
  'Credit card required to be on file in order to run CI jobs',
);
export const IDENTITY_VERIFICATION_REQUIRED_ERROR = __(
  'Identity verification is required in order to run CI jobs',
);
