import { s__, __ } from '~/locale';

//  Translations strings
export const DETAILS_PAGE_TITLE = s__('ContainerRegistry|%{imageName} tags');
export const DELETE_TAG_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while marking the tag for deletion.',
);
export const DELETE_TAG_SUCCESS_MESSAGE = s__(
  'ContainerRegistry|Tag successfully marked for deletion.',
);
export const DELETE_TAGS_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while marking the tags for deletion.',
);
export const DELETE_TAGS_SUCCESS_MESSAGE = s__(
  'ContainerRegistry|Tags successfully marked for deletion.',
);

export const FETCH_IMAGE_DETAILS_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while fetching the image details.',
);

export const TAGS_LIST_TITLE = s__('ContainerRegistry|Image tags');
export const DIGEST_LABEL = s__('ContainerRegistry|Digest: %{imageId}');
export const CREATED_AT_LABEL = s__('ContainerRegistry|Published %{timeInfo}');
export const PUBLISHED_DETAILS_ROW_TEXT = s__(
  'ContainerRegistry|Published to the %{repositoryPath} image repository at %{time} on %{date}',
);
export const MANIFEST_DETAILS_ROW_TEST = s__('ContainerRegistry|Manifest digest: %{digest}');
export const CONFIGURATION_DETAILS_ROW_TEST = s__(
  'ContainerRegistry|Configuration digest: %{digest}',
);

export const REMOVE_TAG_BUTTON_TITLE = s__('ContainerRegistry|Remove tag');
export const REMOVE_TAGS_BUTTON_TITLE = s__('ContainerRegistry|Delete selected');
export const REMOVE_TAG_CONFIRMATION_TEXT = s__(
  `ContainerRegistry|You are about to remove %{item}. Are you sure?`,
);
export const REMOVE_TAGS_CONFIRMATION_TEXT = s__(
  `ContainerRegistry|You are about to remove %{item} tags. Are you sure?`,
);
export const EMPTY_IMAGE_REPOSITORY_TITLE = s__('ContainerRegistry|This image has no active tags');
export const EMPTY_IMAGE_REPOSITORY_MESSAGE = s__(
  `ContainerRegistry|The last tag related to this image was recently removed.
This empty image and any associated data will be automatically removed as part of the regular Garbage Collection process.
If you have any questions, contact your administrator.`,
);
export const ADMIN_GARBAGE_COLLECTION_TIP = s__(
  'ContainerRegistry|Remember to run %{docLinkStart}garbage collection%{docLinkEnd} to remove the stale data from storage.',
);

export const REMOVE_TAG_BUTTON_DISABLE_TOOLTIP = s__(
  'ContainerRegistry|Deletion disabled due to missing or insufficient permissions.',
);

export const MISSING_MANIFEST_WARNING_TOOLTIP = s__(
  'ContainerRegistry|Invalid tag: missing manifest digest',
);

export const NOT_AVAILABLE_TEXT = __('N/A');
export const NOT_AVAILABLE_SIZE = __('0 bytes');
// Parameters

export const DEFAULT_PAGE = 1;
export const DEFAULT_PAGE_SIZE = 10;
export const GROUP_PAGE_TYPE = 'groups';
export const ALERT_SUCCESS_TAG = 'success_tag';
export const ALERT_DANGER_TAG = 'danger_tag';
export const ALERT_SUCCESS_TAGS = 'success_tags';
export const ALERT_DANGER_TAGS = 'danger_tags';

export const ALERT_MESSAGES = {
  [ALERT_SUCCESS_TAG]: DELETE_TAG_SUCCESS_MESSAGE,
  [ALERT_DANGER_TAG]: DELETE_TAG_ERROR_MESSAGE,
  [ALERT_SUCCESS_TAGS]: DELETE_TAGS_SUCCESS_MESSAGE,
  [ALERT_DANGER_TAGS]: DELETE_TAGS_ERROR_MESSAGE,
};
