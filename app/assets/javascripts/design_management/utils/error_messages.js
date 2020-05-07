import { __, s__, n__, sprintf } from '~/locale';

export const ADD_DISCUSSION_COMMENT_ERROR = s__(
  'DesignManagement|Could not add a new comment. Please try again.',
);

export const ADD_IMAGE_DIFF_NOTE_ERROR = s__(
  'DesignManagement|Could not create new discussion. Please try again.',
);

export const UPDATE_IMAGE_DIFF_NOTE_ERROR = s__(
  'DesignManagement|Could not update discussion. Please try again.',
);

export const UPLOAD_DESIGN_ERROR = s__(
  'DesignManagement|Error uploading a new design. Please try again.',
);

export const UPLOAD_DESIGN_INVALID_FILETYPE_ERROR = __(
  'Could not upload your designs as one or more files uploaded are not supported.',
);

export const DESIGN_NOT_FOUND_ERROR = __('Could not find design.');

export const DESIGN_VERSION_NOT_EXIST_ERROR = __('Requested design version does not exist.');

const DESIGN_UPLOAD_SKIPPED_MESSAGE = s__('DesignManagement|Upload skipped.');

const ALL_DESIGNS_SKIPPED_MESSAGE = `${DESIGN_UPLOAD_SKIPPED_MESSAGE} ${s__(
  'The designs you tried uploading did not change.',
)}`;

export const EXISTING_DESIGN_DROP_MANY_FILES_MESSAGE = __(
  'You can only upload one design when dropping onto an existing design.',
);

export const EXISTING_DESIGN_DROP_INVALID_FILENAME_MESSAGE = __(
  'You must upload a file with the same file name when dropping onto an existing design.',
);

const MAX_SKIPPED_FILES_LISTINGS = 5;

const oneDesignSkippedMessage = filename =>
  `${DESIGN_UPLOAD_SKIPPED_MESSAGE} ${sprintf(s__('DesignManagement|%{filename} did not change.'), {
    filename,
  })}`;

/**
 * Return warning message indicating that some (but not all) uploaded
 * files were skipped.
 * @param {Array<{ filename }>} skippedFiles
 */
const someDesignsSkippedMessage = skippedFiles => {
  const designsSkippedMessage = `${DESIGN_UPLOAD_SKIPPED_MESSAGE} ${s__(
    'Some of the designs you tried uploading did not change:',
  )}`;

  const moreText = sprintf(s__(`DesignManagement|and %{moreCount} more.`), {
    moreCount: skippedFiles.length - MAX_SKIPPED_FILES_LISTINGS,
  });

  return `${designsSkippedMessage} ${skippedFiles
    .slice(0, MAX_SKIPPED_FILES_LISTINGS)
    .map(({ filename }) => filename)
    .join(', ')}${skippedFiles.length > MAX_SKIPPED_FILES_LISTINGS ? `, ${moreText}` : '.'}`;
};

export const designDeletionError = ({ singular = true } = {}) => {
  const design = singular ? __('a design') : __('designs');
  return sprintf(s__('Could not delete %{design}. Please try again.'), {
    design,
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

    return n__(oneDesignSkippedMessage(filename), ALL_DESIGNS_SKIPPED_MESSAGE, skippedFiles.length);
  }

  return someDesignsSkippedMessage(skippedFiles);
};
