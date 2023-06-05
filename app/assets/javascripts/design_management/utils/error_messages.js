import { __, s__, n__, sprintf } from '~/locale';
import { MAXIMUM_FILE_UPLOAD_LIMIT } from '../constants';

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

export const UPLOAD_DESIGN_ERROR = s__(
  'DesignManagement|Error uploading a new design. Please try again.',
);

export const UPLOAD_DESIGN_INVALID_FILETYPE_ERROR = __(
  'Could not upload your designs as one or more files uploaded are not supported.',
);

export const DESIGN_NOT_FOUND_ERROR = __('Could not find design.');

export const DESIGN_VERSION_NOT_EXIST_ERROR = __('Requested design version does not exist.');

export const EXISTING_DESIGN_DROP_MANY_FILES_MESSAGE = __(
  'Your update failed. You can only upload one design when dropping onto an existing design.',
);

export const EXISTING_DESIGN_DROP_INVALID_FILENAME_MESSAGE = __(
  'Your update failed. You must upload a file with the same file name when dropping onto an existing design.',
);

export const MOVE_DESIGN_ERROR = __(
  'Something went wrong when reordering designs. Please try again',
);

export const CREATE_DESIGN_TODO_ERROR = __('Failed to create a to-do item for the design.');

export const CREATE_DESIGN_TODO_EXISTS_ERROR = __('There is already a to-do item for this design.');

export const DELETE_DESIGN_TODO_ERROR = __('Failed to remove a to-do item for the design.');

export const TOGGLE_TODO_ERROR = __('Failed to toggle the to-do status for the design.');

const DESIGN_UPLOAD_SKIPPED_MESSAGE = s__('DesignManagement|Upload skipped. %{reason}');

const MAX_SKIPPED_FILES_LISTINGS = 5;

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

export const designDeletionError = (designsCount = 1) => {
  return n__(
    'Failed to archive a design. Please try again.',
    'Failed to archive designs. Please try again.',
    designsCount,
  );
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

export const MAXIMUM_FILE_UPLOAD_LIMIT_REACHED = sprintf(
  s__(
    'DesignManagement|The maximum number of designs allowed to be uploaded is %{upload_limit}. Please try again.',
  ),
  {
    upload_limit: MAXIMUM_FILE_UPLOAD_LIMIT,
  },
);

export const UPDATE_DESCRIPTION_ERROR = s__(
  'DesignManagement|Could not update description. Please try again.',
);
