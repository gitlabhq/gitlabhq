import { s__ } from '~/locale';

// List page

export const CONTAINER_REGISTRY_TITLE = s__('ContainerRegistry|Container Registry');
export const CONNECTION_ERROR_TITLE = s__('ContainerRegistry|Docker connection error');
export const CONNECTION_ERROR_MESSAGE = s__(
  `ContainerRegistry|We are having trouble connecting to Docker, which could be due to an issue with your project name or path. %{docLinkStart}More Information%{docLinkEnd}`,
);
export const LIST_INTRO_TEXT = s__(
  `ContainerRegistry|With the Docker Container Registry integrated into GitLab, every project can have its own space to store its Docker images. %{docLinkStart}More Information%{docLinkEnd}`,
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

// Image details page

export const DELETE_TAG_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while deleting the tag.',
);
export const DELETE_TAG_SUCCESS_MESSAGE = s__('ContainerRegistry|Tag deleted successfully');
export const DELETE_TAGS_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while deleting the tags.',
);
export const DELETE_TAGS_SUCCESS_MESSAGE = s__('ContainerRegistry|Tags deleted successfully');

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

// Expiration policies

export const EXPIRATION_POLICY_ALERT_TITLE = s__(
  'ContainerRegistry|Retention policy has been Enabled',
);
export const EXPIRATION_POLICY_ALERT_PRIMARY_BUTTON = s__('ContainerRegistry|Edit Settings');
export const EXPIRATION_POLICY_ALERT_FULL_MESSAGE = s__(
  'ContainerRegistry|The retention and expiration policy for this Container Registry has been enabled and will run in %{days}. For more information visit the %{linkStart}documentation%{linkEnd}',
);
export const EXPIRATION_POLICY_ALERT_SHORT_MESSAGE = s__(
  'ContainerRegistry|The retention and expiration policy for this Container Registry has been enabled. For more information visit the %{linkStart}documentation%{linkEnd}',
);

// Quick Start

export const QUICK_START = s__('ContainerRegistry|Quick Start');
export const LOGIN_COMMAND_LABEL = s__('ContainerRegistry|Login');
export const COPY_LOGIN_TITLE = s__('ContainerRegistry|Copy login command');
export const BUILD_COMMAND_LABEL = s__('ContainerRegistry|Build an image');
export const COPY_BUILD_TITLE = s__('ContainerRegistry|Copy build command');
export const PUSH_COMMAND_LABEL = s__('ContainerRegistry|Push an image');
export const COPY_PUSH_TITLE = s__('ContainerRegistry|Copy push command');

// Image state

export const IMAGE_DELETE_SCHEDULED_STATUS = 'delete_scheduled';
export const IMAGE_FAILED_DELETED_STATUS = 'delete_failed';
