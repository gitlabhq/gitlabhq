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

/**
 * Checks if the target is the Web IDE
 * @param {string} target - The target editor ('ide' or 'simple')
 * @returns {boolean} - Whether the target is the Web IDE
 */
export const isIdeTarget = (target) => {
  return target === 'ide';
};

/**
 * Determines which fork suggestion to show based on the selected editor
 * Single file editor shows fork suggestion when the ref is not on top of the branch.
 * WebIDE does not have this limitation.
 * @param {string} target - The target editor ('ide' or 'simple')
 * @param {boolean} shouldShowWebIdeForkSuggestion - Whether to show fork suggestion for Web IDE
 * @param {boolean} shouldShowSingleFileEditorForkSuggestion - Whether to show fork suggestion for single file editor
 * @returns {boolean} - Whether to show fork suggestion for the selected editor
 */
export const forkSuggestionForSelectedEditor = (
  target,
  shouldShowWebIdeForkSuggestion,
  shouldShowSingleFileEditorForkSuggestion,
) => {
  return isIdeTarget(target)
    ? shouldShowWebIdeForkSuggestion
    : shouldShowSingleFileEditorForkSuggestion;
};
