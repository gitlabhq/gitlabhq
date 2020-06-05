import { s__ } from '~/locale';

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
export const LIST_LABEL_TAG = s__('ContainerRegistry|Tag');
export const LIST_LABEL_IMAGE_ID = s__('ContainerRegistry|Image ID');
export const LIST_LABEL_SIZE = s__('ContainerRegistry|Compressed Size');
export const LIST_LABEL_LAST_UPDATED = s__('ContainerRegistry|Last Updated');
export const REMOVE_TAG_BUTTON_TITLE = s__('ContainerRegistry|Remove tag');
export const REMOVE_TAGS_BUTTON_TITLE = s__('ContainerRegistry|Remove selected tags');
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

// Parameters

export const DEFAULT_PAGE = 1;
export const DEFAULT_PAGE_SIZE = 10;
export const GROUP_PAGE_TYPE = 'groups';
export const LIST_KEY_TAG = 'name';
export const LIST_KEY_IMAGE_ID = 'short_revision';
export const LIST_KEY_SIZE = 'total_size';
export const LIST_KEY_LAST_UPDATED = 'created_at';
export const LIST_KEY_ACTIONS = 'actions';
export const LIST_KEY_CHECKBOX = 'checkbox';
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
