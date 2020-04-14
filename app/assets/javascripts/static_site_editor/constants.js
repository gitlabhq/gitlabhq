import { s__ } from '~/locale';

export const BRANCH_SUFFIX_COUNT = 8;
export const DEFAULT_TARGET_BRANCH = 'master';

export const SUBMIT_CHANGES_BRANCH_ERROR = s__('StaticSiteEditor|Branch could not be created.');
export const SUBMIT_CHANGES_COMMIT_ERROR = s__(
  'StaticSiteEditor|Could not commit the content changes.',
);
export const SUBMIT_CHANGES_MERGE_REQUEST_ERROR = s__(
  'StaticSiteEditor|Could not create merge request.',
);
