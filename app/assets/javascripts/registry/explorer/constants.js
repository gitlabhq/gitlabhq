import { s__ } from '~/locale';

// List page

export const CONTAINER_REGISTRY_TITLE = s__('ContainerRegistry|Container Registry');
export const CONNECTION_ERROR_TITLE = s__('ContainerRegistry|Docker connection error');
export const CONNECTION_ERROR_MESSAGE = s__(
  `ContainerRegistry|We are having trouble connecting to the Registry, which could be due to an issue with your project name or path. %{docLinkStart}More information%{docLinkEnd}`,
);
export const LIST_INTRO_TEXT = s__(
  `ContainerRegistry|With the GitLab Container Registry, every project can have its own space to store images. %{docLinkStart}More information%{docLinkEnd}`,
);

export const LIST_DELETE_BUTTON_DISABLED = s__(
  'ContainerRegistry|Missing or insufficient permission, delete button disabled',
);
export const REMOVE_REPOSITORY_LABEL = s__('ContainerRegistry|Remove repository');
export const REMOVE_REPOSITORY_MODAL_TEXT = s__(
  'ContainerRegistry|You are about to remove repository %{title}. Once you confirm, this repository will be permanently deleted.',
);
export const ROW_SCHEDULED_FOR_DELETION = s__(
  `ContainerRegistry|This image repository is scheduled for deletion`,
);
export const FETCH_IMAGES_LIST_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while fetching the repository list.',
);
export const FETCH_TAGS_LIST_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while fetching the tags list.',
);
export const DELETE_IMAGE_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while scheduling %{title} for deletion. Please try again.',
);
export const ASYNC_DELETE_IMAGE_ERROR_MESSAGE = s__(
  `ContainerRegistry|There was an error during the deletion of this image repository, please try again.`,
);
export const DELETE_IMAGE_SUCCESS_MESSAGE = s__(
  'ContainerRegistry|%{title} was successfully scheduled for deletion',
);

export const IMAGE_REPOSITORY_LIST_LABEL = s__('ContainerRegistry|Image Repositories');

export const SEARCH_PLACEHOLDER_TEXT = s__('ContainerRegistry|Filter by name');

export const EMPTY_RESULT_TITLE = s__('ContainerRegistry|Sorry, your filter produced no results.');
export const EMPTY_RESULT_MESSAGE = s__(
  'ContainerRegistry|To widen your search, change or remove the filters above.',
);

// Image details page

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

export const DEFAULT_PAGE = 1;
export const DEFAULT_PAGE_SIZE = 10;

export const GROUP_PAGE_TYPE = 'groups';

export const LIST_KEY_TAG = 'name';
export const LIST_KEY_IMAGE_ID = 'short_revision';
export const LIST_KEY_SIZE = 'total_size';
export const LIST_KEY_LAST_UPDATED = 'created_at';
export const LIST_KEY_ACTIONS = 'actions';
export const LIST_KEY_CHECKBOX = 'checkbox';

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

// Expiration policies

export const EXPIRATION_POLICY_WILL_RUN_IN = s__(
  'ContainerRegistry|Expiration policy will run in %{time}',
);

export const EXPIRATION_POLICY_DISABLED_TEXT = s__(
  'ContainerRegistry|Expiration policy is disabled',
);

export const EXPIRATION_POLICY_DISABLED_MESSAGE = s__(
  'ContainerRegistry|Expiration policies help manage the storage space used by the Container Registry, but the expiration policies for this registry are disabled. Contact your administrator to enable. %{docLinkStart}More information%{docLinkEnd}',
);

// Quick Start

export const QUICK_START = s__('ContainerRegistry|CLI Commands');
export const LOGIN_COMMAND_LABEL = s__('ContainerRegistry|Login');
export const COPY_LOGIN_TITLE = s__('ContainerRegistry|Copy login command');
export const BUILD_COMMAND_LABEL = s__('ContainerRegistry|Build an image');
export const COPY_BUILD_TITLE = s__('ContainerRegistry|Copy build command');
export const PUSH_COMMAND_LABEL = s__('ContainerRegistry|Push an image');
export const COPY_PUSH_TITLE = s__('ContainerRegistry|Copy push command');

// Image state

export const IMAGE_DELETE_SCHEDULED_STATUS = 'delete_scheduled';
export const IMAGE_FAILED_DELETED_STATUS = 'delete_failed';
