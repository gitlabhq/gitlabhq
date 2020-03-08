import { s__ } from '~/locale';

export const FETCH_IMAGES_LIST_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while fetching the packages list.',
);
export const FETCH_TAGS_LIST_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while fetching the tags list.',
);

export const DELETE_IMAGE_ERROR_MESSAGE = s__(
  'ContainerRegistry|Something went wrong while deleting the image.',
);
export const DELETE_IMAGE_SUCCESS_MESSAGE = s__('ContainerRegistry|Image deleted successfully');
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
export const LIST_LABEL_SIZE = s__('ContainerRegistry|Size');
export const LIST_LABEL_LAST_UPDATED = s__('ContainerRegistry|Last Updated');

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
