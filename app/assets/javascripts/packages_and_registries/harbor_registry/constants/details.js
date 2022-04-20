import { s__, __ } from '~/locale';

export const UPDATED_AT = s__('HarborRegistry|Last updated %{time}');

export const MISSING_OR_DELETED_IMAGE_TITLE = s__(
  'HarborRegistry|The image repository could not be found.',
);

export const MISSING_OR_DELETED_IMAGE_MESSAGE = s__(
  'HarborRegistry|The requested image repository does not exist or has been deleted. If you think this is an error, try refreshing the page.',
);

export const NO_TAGS_TITLE = s__('HarborRegistry|This image has no active tags');

export const NO_TAGS_MESSAGE = s__(
  `HarborRegistry|The last tag related to this image was recently removed.
This empty image and any associated data will be automatically removed as part of the regular Garbage Collection process.
If you have any questions, contact your administrator.`,
);

export const NO_TAGS_MATCHING_FILTERS_TITLE = s__('HarborRegistry|The filter returned no results');

export const NO_TAGS_MATCHING_FILTERS_DESCRIPTION = s__(
  'HarborRegistry|Please try different search criteria',
);

export const DIGEST_LABEL = s__('HarborRegistry|Digest: %{imageId}');
export const CREATED_AT_LABEL = s__('HarborRegistry|Published %{timeInfo}');
export const PUBLISHED_DETAILS_ROW_TEXT = s__(
  'HarborRegistry|Published to the %{repositoryPath} image repository at %{time} on %{date}',
);
export const MANIFEST_DETAILS_ROW_TEST = s__('HarborRegistry|Manifest digest: %{digest}');
export const CONFIGURATION_DETAILS_ROW_TEST = s__('HarborRegistry|Configuration digest: %{digest}');
export const MISSING_MANIFEST_WARNING_TOOLTIP = s__(
  'HarborRegistry|Invalid tag: missing manifest digest',
);

export const NOT_AVAILABLE_TEXT = __('N/A');
export const NOT_AVAILABLE_SIZE = __('0 bytes');
