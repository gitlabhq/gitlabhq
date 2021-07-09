import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __ } from '~/locale';

//  Translations strings
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
export const REMOVE_TAGS_BUTTON_TITLE = s__('ContainerRegistry|Delete selected tags');

export const REMOVE_TAG_CONFIRMATION_TEXT = s__(
  `ContainerRegistry|You are about to remove %{item}. Are you sure?`,
);
export const REMOVE_TAGS_CONFIRMATION_TEXT = s__(
  `ContainerRegistry|You are about to remove %{item} tags. Are you sure?`,
);
export const NO_TAGS_TITLE = s__('ContainerRegistry|This image has no active tags');
export const NO_TAGS_MESSAGE = s__(
  `ContainerRegistry|The last tag related to this image was recently removed.
This empty image and any associated data will be automatically removed as part of the regular Garbage Collection process.
If you have any questions, contact your administrator.`,
);

export const MISSING_OR_DELETED_IMAGE_TITLE = s__(
  'ContainerRegistry|The image repository could not be found.',
);
export const MISSING_OR_DELETED_IMAGE_MESSAGE = s__(
  'ContainerRegistry|The requested image repository does not exist or has been deleted. If you think this is an error, try refreshing the page.',
);

export const MISSING_OR_DELETED_IMAGE_BREADCRUMB = s__(
  'ContainerRegistry|Image repository not found',
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

export const UPDATED_AT = s__('ContainerRegistry|Last updated %{time}');

export const NOT_AVAILABLE_TEXT = __('N/A');
export const NOT_AVAILABLE_SIZE = __('0 bytes');

export const CLEANUP_UNSCHEDULED_TEXT = s__('ContainerRegistry|Cleanup will run %{time}');
export const CLEANUP_SCHEDULED_TEXT = s__('ContainerRegistry|Cleanup pending');
export const CLEANUP_ONGOING_TEXT = s__('ContainerRegistry|Cleanup in progress');
export const CLEANUP_UNFINISHED_TEXT = s__('ContainerRegistry|Cleanup incomplete');
export const CLEANUP_DISABLED_TEXT = s__('ContainerRegistry|Cleanup disabled');

export const CLEANUP_SCHEDULED_TOOLTIP = s__('ContainerRegistry|Cleanup will run soon');
export const CLEANUP_ONGOING_TOOLTIP = s__('ContainerRegistry|Cleanup is currently removing tags');
export const CLEANUP_UNFINISHED_TOOLTIP = s__(
  'ContainerRegistry|Cleanup ran but some tags were not removed',
);
export const CLEANUP_DISABLED_TOOLTIP = s__(
  'ContainerRegistry|Cleanup is disabled for this project',
);

export const CLEANUP_STATUS_SCHEDULED = s__('ContainerRegistry|Cleanup will run soon');
export const CLEANUP_STATUS_ONGOING = s__('ContainerRegistry|Cleanup is ongoing');
export const CLEANUP_STATUS_UNFINISHED = s__('ContainerRegistry|Cleanup timed out');

export const DETAILS_DELETE_IMAGE_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while scheduling the image for deletion.',
);

export const DELETE_IMAGE_CONFIRMATION_TITLE = s__('ContainerRegistry|Delete image repository?');
export const DELETE_IMAGE_CONFIRMATION_TEXT = s__(
  'ContainerRegistry|Deleting the image repository will delete all images and tags inside. This action cannot be undone.',
);

export const SCHEDULED_FOR_DELETION_STATUS_TITLE = s__(
  'ContainerRegistry|Image repository will be deleted',
);
export const SCHEDULED_FOR_DELETION_STATUS_MESSAGE = s__(
  'ContainerRegistry|This image repository will be deleted. %{linkStart}Learn more.%{linkEnd}',
);

export const FAILED_DELETION_STATUS_TITLE = s__(
  'ContainerRegistry|Image repository deletion failed',
);
export const FAILED_DELETION_STATUS_MESSAGE = s__(
  'ContainerRegistry|This image repository has failed to be deleted',
);

export const ROOT_IMAGE_TOOLTIP = s__(
  'ContainerRegistry|Image repository with no name located at the project URL.',
);

// Parameters

export const DEFAULT_PAGE = 1;
export const DEFAULT_PAGE_SIZE = 10;
export const GROUP_PAGE_TYPE = 'groups';
export const ALERT_SUCCESS_TAG = 'success_tag';
export const ALERT_DANGER_TAG = 'danger_tag';
export const ALERT_SUCCESS_TAGS = 'success_tags';
export const ALERT_DANGER_TAGS = 'danger_tags';
export const ALERT_DANGER_IMAGE = 'danger_image';

export const DELETE_SCHEDULED = 'DELETE_SCHEDULED';
export const DELETE_FAILED = 'DELETE_FAILED';

export const ALERT_MESSAGES = {
  [ALERT_SUCCESS_TAG]: DELETE_TAG_SUCCESS_MESSAGE,
  [ALERT_DANGER_TAG]: DELETE_TAG_ERROR_MESSAGE,
  [ALERT_SUCCESS_TAGS]: DELETE_TAGS_SUCCESS_MESSAGE,
  [ALERT_DANGER_TAGS]: DELETE_TAGS_ERROR_MESSAGE,
  [ALERT_DANGER_IMAGE]: DETAILS_DELETE_IMAGE_ERROR_MESSAGE,
};

export const UNFINISHED_STATUS = 'UNFINISHED';
export const UNSCHEDULED_STATUS = 'UNSCHEDULED';
export const SCHEDULED_STATUS = 'SCHEDULED';
export const ONGOING_STATUS = 'ONGOING';

export const IMAGE_STATUS_TITLES = {
  [DELETE_SCHEDULED]: SCHEDULED_FOR_DELETION_STATUS_TITLE,
  [DELETE_FAILED]: FAILED_DELETION_STATUS_TITLE,
};

export const IMAGE_STATUS_MESSAGES = {
  [DELETE_SCHEDULED]: SCHEDULED_FOR_DELETION_STATUS_MESSAGE,
  [DELETE_FAILED]: FAILED_DELETION_STATUS_MESSAGE,
};

export const IMAGE_STATUS_ALERT_TYPE = {
  [DELETE_SCHEDULED]: 'info',
  [DELETE_FAILED]: 'warning',
};

export const PACKAGE_DELETE_HELP_PAGE_PATH = helpPagePath('user/packages/container_registry', {
  anchor: 'delete-images',
});
