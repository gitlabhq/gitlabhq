import { __ } from '~/locale';

export const FETCH_IMAGES_LIST_ERROR_MESSAGE = __(
  'Something went wrong while fetching the packages list.',
);
export const FETCH_TAGS_LIST_ERROR_MESSAGE = __(
  'Something went wrong while fetching the tags list.',
);

export const DELETE_IMAGE_ERROR_MESSAGE = __('Something went wrong while deleting the image.');
export const DELETE_IMAGE_SUCCESS_MESSAGE = __('Image deleted successfully');
export const DELETE_TAG_ERROR_MESSAGE = __('Something went wrong while deleting the tag.');
export const DELETE_TAG_SUCCESS_MESSAGE = __('Tag deleted successfully');
export const DELETE_TAGS_ERROR_MESSAGE = __('Something went wrong while deleting the tags.');
export const DELETE_TAGS_SUCCESS_MESSAGE = __('Tags deleted successfully');

export const DEFAULT_PAGE = 1;
export const DEFAULT_PAGE_SIZE = 10;

export const GROUP_PAGE_TYPE = 'groups';

export const LIST_KEY_TAG = 'name';
export const LIST_KEY_IMAGE_ID = 'short_revision';
export const LIST_KEY_SIZE = 'total_size';
export const LIST_KEY_LAST_UPDATED = 'created_at';
export const LIST_KEY_ACTIONS = 'actions';
export const LIST_KEY_CHECKBOX = 'checkbox';

export const LIST_LABEL_TAG = __('Tag');
export const LIST_LABEL_IMAGE_ID = __('Image ID');
export const LIST_LABEL_SIZE = __('Size');
export const LIST_LABEL_LAST_UPDATED = __('Last Updated');
