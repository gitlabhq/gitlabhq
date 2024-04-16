import { s__ } from '~/locale';

export const BRANCH_FILTER_ALL_BRANCHES = 'all_branches';
export const BRANCH_FILTER_WILDCARD = 'wildcard';
export const BRANCH_FILTER_REGEX = 'regex';

export const WILDCARD_CODE_STABLE = '*-stable';
export const WILDCARD_CODE_PRODUCTION = 'production/*';

export const REGEX_CODE = '^(feature|hotfix)/';

export const descriptionText = {
  [BRANCH_FILTER_WILDCARD]: s__(
    'Webhooks|Wildcards such as %{WILDCARD_CODE_STABLE} or %{WILDCARD_CODE_PRODUCTION} are supported.',
  ),
  [BRANCH_FILTER_REGEX]: s__('Webhooks|Regular expressions such as %{REGEX_CODE} are supported.'),
};

export const MASK_ITEM_VALUE_HIDDEN = '************';

export const CUSTOM_HEADER_KEY_PATTERN = /^[A-Za-z]+[0-9]*(?:[._-][A-Za-z0-9]+)*$/;
