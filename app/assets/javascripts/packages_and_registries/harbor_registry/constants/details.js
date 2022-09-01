import { s__, __ } from '~/locale';

export const FETCH_ARTIFACT_LIST_ERROR_MESSAGE = s__(
  'HarborRegistry|Something went wrong while fetching the artifact list.',
);

export const NO_ARTIFACTS_TITLE = s__('HarborRegistry|This image has no artifacts');

export const NO_TAGS_MATCHING_FILTERS_TITLE = s__('HarborRegistry|The filter returned no results');

export const NO_TAGS_MATCHING_FILTERS_DESCRIPTION = s__(
  'HarborRegistry|Please try different search criteria',
);

export const DIGEST_LABEL = s__('HarborRegistry|Digest: %{imageId}');
export const CREATED_AT_LABEL = s__('HarborRegistry|Published %{timeInfo}');

export const NOT_AVAILABLE_TEXT = __('Not applicable.');
export const NOT_AVAILABLE_SIZE = __('0 bytes');

export const TOKEN_TYPE_TAG_NAME = 'tag_name';

export const FETCH_TAGS_ERROR_MESSAGE = s__(
  'HarborRegistry|Something went wrong while fetching the tags.',
);

export const TAG_LABEL = s__('HarborRegistry|Tag');
