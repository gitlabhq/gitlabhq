import { __ } from '~/locale';
// WARNING: replace this with something
// more sensical as per https://gitlab.com/gitlab-org/gitlab/issues/118611
export const VALID_DESIGN_FILE_MIMETYPE = {
  mimetype: 'image/*',
  regex: /image\/.+/,
};

export const ACTIVE_DISCUSSION_SOURCE_TYPES = {
  pin: 'pin',
  discussion: 'discussion',
  url: 'url',
};

export const DESIGN_DETAIL_LAYOUT_CLASSLIST = ['design-detail-layout', 'overflow-hidden', 'm-0'];

export const MAXIMUM_FILE_UPLOAD_LIMIT = 10;

export const DELETE_NOTE_ERROR_MSG = __(
  'Something went wrong when deleting a comment. Please try again.',
);
