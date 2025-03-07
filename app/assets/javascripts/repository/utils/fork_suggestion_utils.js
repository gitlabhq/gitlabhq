import { isLoggedIn } from '~/lib/utils/common_utils';

/**
 * Checks if the user can fork the project
 * @param {Object} userPermissions - User permissions object
 * @param {boolean} isUsingLfs - Whether the project is using LFS
 * @returns {boolean}
 */
export const canFork = (userPermissions, isUsingLfs) => {
  const { createMergeRequestIn, forkProject } = userPermissions;
  return isLoggedIn() && !isUsingLfs && createMergeRequestIn && forkProject;
};

/**
 * Checks if the fork suggestion should be shown for single file editor
 * @param {Object} userPermissions - User permissions object
 * @param {boolean} isUsingLfs - Whether the project is using LFS
 * @param {boolean} canModifyBlob - Whether the user can modify the blob
 * @returns {boolean}
 */
export const showSingleFileEditorForkSuggestion = (userPermissions, isUsingLfs, canModifyBlob) => {
  return canFork(userPermissions, isUsingLfs) && !canModifyBlob;
};

/**
 * Checks if the fork suggestion should be shown for Web IDE
 * @param {Object} userPermissions - User permissions object
 * @param {boolean} isUsingLfs - Whether the project is using LFS
 * @param {boolean} canModifyBlobWithWebIde - Whether the user can modify the blob with Web IDE
 * @returns {boolean}
 */
export const showWebIdeForkSuggestion = (userPermissions, isUsingLfs, canModifyBlobWithWebIde) => {
  return canFork(userPermissions, isUsingLfs) && !canModifyBlobWithWebIde;
};

/**
 * Checks if the fork suggestion should be shown
 * @param {Object} userPermissions - User permissions object
 * @param {boolean} isUsingLfs - Whether the project is using LFS
 * @param {Object} blobInfo - blobInfo object, including canModifyBlob and canModifyBlobWithWebIde
 * @returns {boolean}
 */
export const showForkSuggestion = (userPermissions, isUsingLfs, blobInfo) => {
  return (
    showSingleFileEditorForkSuggestion(userPermissions, isUsingLfs, blobInfo.canModifyBlob) ||
    showWebIdeForkSuggestion(userPermissions, isUsingLfs, blobInfo.canModifyBlobWithWebIde)
  );
};
