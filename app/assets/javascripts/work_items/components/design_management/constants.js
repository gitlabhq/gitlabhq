import { n__, s__, sprintf } from '~/locale';

export const DESIGN_DETAIL_LAYOUT_CLASSLIST = [
  'design-detail-layout',
  'gl-overflow-hidden',
  'gl-m-0',
];

export const ACTIVE_DISCUSSION_SOURCE_TYPES = {
  pin: 'pin',
  discussion: 'discussion',
  url: 'url',
};

export const ALERT_VARIANTS = {
  danger: 'danger',
  info: 'info',
};

export const VALID_DESIGN_FILE_MIMETYPE = {
  mimetype: 'image/png, image/jpg, image/jpeg, image/gif, image/bmp, image/tiff, image/ico',
  regex: /image\/.+/,
};

export const MAXIMUM_FILE_UPLOAD_LIMIT = 10;

export const MAXIMUM_FILE_UPLOAD_LIMIT_REACHED = sprintf(
  s__(
    'DesignManagement|The maximum number of designs allowed to be uploaded is %{upload_limit}. Please try again.',
  ),
  {
    upload_limit: MAXIMUM_FILE_UPLOAD_LIMIT,
  },
);

export const DESIGN_NOT_FOUND_ERROR = s__('DesignManagement|Could not find design.');

export const DESIGN_VERSION_NOT_EXIST_ERROR = s__(
  'DesignManagement|Requested design version does not exist.',
);

export const DESIGN_SINGLE_ARCHIVE_ERROR = s__(
  'DesignManagement|Failed to archive a design. Please try again.',
);

const DESIGN_UPLOAD_SKIPPED_MESSAGE = s__('DesignManagement|Upload skipped. %{reason}');
const MAX_SKIPPED_FILES_LISTINGS = 5;

export const UPDATE_DESCRIPTION_ERROR = s__(
  'DesignManagement|Could not update description. Please try again.',
);

export const UPLOAD_DESIGN_ERROR_MESSAGE = s__(
  'DesignManagement|Error uploading a new design. Please try again.',
);

export const ADD_DISCUSSION_COMMENT_ERROR = s__(
  'DesignManagement|Could not add a new comment. Please try again.',
);

export const ADD_IMAGE_DIFF_NOTE_ERROR = s__(
  'DesignManagement|Could not create new discussion. Please try again.',
);

export const UPDATE_IMAGE_DIFF_NOTE_ERROR = s__(
  'DesignManagement|Could not update discussion. Please try again.',
);

export const UPDATE_NOTE_ERROR = s__(
  'DesignManagement|Could not update comment. Please try again.',
);

export const DELETE_NOTE_ERROR = s__(
  'DesignManagement|Could not delete comment. Please try again.',
);

export const RESOLVE_NOTE_ERROR = s__(
  'DesignManagement|Could not resolve comment. Please try again.',
);

export const AWARD_EMOJI_TO_NOTE_ERROR = s__(
  'DesignManagement|Could not award emoji. Please try again.',
);

export const TYPENAME_DISCUSSION = 'Discussion';
export const TYPENAME_USER = 'User';

export const MOVE_DESIGN_ERROR = s__(
  'DesignManagement|Something went wrong when reordering designs. Please try again',
);

/**
 * Return warning message indicating that some (but not all) uploaded
 * files were skipped.
 * @param {Array<{ filename }>} skippedFiles
 */
const someDesignsSkippedMessage = (skippedFiles) => {
  const skippedFilesList = skippedFiles
    .slice(0, MAX_SKIPPED_FILES_LISTINGS)
    .map(({ filename }) => filename)
    .join(', ');

  const uploadSkippedReason =
    skippedFiles.length > MAX_SKIPPED_FILES_LISTINGS
      ? sprintf(
          s__(
            'DesignManagement|Some of the designs you tried uploading did not change: %{skippedFiles} and %{moreCount} more.',
          ),
          {
            skippedFiles: skippedFilesList,
            moreCount: skippedFiles.length - MAX_SKIPPED_FILES_LISTINGS,
          },
        )
      : sprintf(
          s__(
            'DesignManagement|Some of the designs you tried uploading did not change: %{skippedFiles}.',
          ),
          { skippedFiles: skippedFilesList },
        );

  return sprintf(DESIGN_UPLOAD_SKIPPED_MESSAGE, {
    reason: uploadSkippedReason,
  });
};

/**
 * Return warning message, if applicable, that one, some or all uploaded
 * files were skipped.
 * @param {Array<{ filename }>} uploadedDesigns
 * @param {Array<{ filename }>} skippedFiles
 */
export const designUploadSkippedWarning = (uploadedDesigns, skippedFiles) => {
  if (skippedFiles.length === 0) {
    return null;
  }

  if (skippedFiles.length === uploadedDesigns.length) {
    const { filename } = skippedFiles[0];

    const uploadSkippedReason = sprintf(
      n__(
        'DesignManagement|%{filename} did not change.',
        'DesignManagement|The designs you tried uploading did not change.',
        skippedFiles.length,
      ),
      { filename },
    );

    return sprintf(DESIGN_UPLOAD_SKIPPED_MESSAGE, {
      reason: uploadSkippedReason,
    });
  }

  return someDesignsSkippedMessage(skippedFiles);
};

export const designArchiveError = (designsCount = 1) => {
  return n__(
    'DesignManagement|Failed to archive a design. Please try again.',
    'DesignManagement|Failed to archive designs. Please try again.',
    designsCount,
  );
};
