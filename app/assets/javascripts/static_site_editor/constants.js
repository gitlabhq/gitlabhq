import { s__, __ } from '~/locale';

export const BRANCH_SUFFIX_COUNT = 8;
export const ISSUABLE_TYPE = 'merge_request';

export const SUBMIT_CHANGES_BRANCH_ERROR = s__('StaticSiteEditor|Branch could not be created.');
export const SUBMIT_CHANGES_COMMIT_ERROR = s__(
  'StaticSiteEditor|Could not commit the content changes.',
);
export const SUBMIT_CHANGES_MERGE_REQUEST_ERROR = s__(
  'StaticSiteEditor|Could not create merge request.',
);
export const LOAD_CONTENT_ERROR = __(
  'An error occurred while loading your content. Please try again.',
);

export const DEFAULT_FORMATTING_CHANGES_COMMIT_MESSAGE = s__(
  'StaticSiteEditor|Automatic formatting changes',
);

export const DEFAULT_FORMATTING_CHANGES_COMMIT_DESCRIPTION = s__(
  'StaticSiteEditor|Markdown formatting preferences introduced by the Static Site Editor',
);

export const DEFAULT_HEADING = s__('StaticSiteEditor|Static site editor');

export const TRACKING_ACTION_CREATE_COMMIT = 'create_commit';
export const TRACKING_ACTION_CREATE_MERGE_REQUEST = 'create_merge_request';
export const TRACKING_ACTION_INITIALIZE_EDITOR = 'initialize_editor';

export const SERVICE_PING_TRACKING_ACTION_CREATE_COMMIT = 'static_site_editor_commits';
export const SERVICE_PING_TRACKING_ACTION_CREATE_MERGE_REQUEST =
  'static_site_editor_merge_requests';

export const MR_META_LOCAL_STORAGE_KEY = 'sse-merge-request-meta-storage-key';
