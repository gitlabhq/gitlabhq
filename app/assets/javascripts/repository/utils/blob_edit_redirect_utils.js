import { visitUrl, joinPaths, mergeUrlParams, removeParams } from '~/lib/utils/url_utility';
import { VARIANT_INFO } from '~/alert';
import { saveAlertToLocalStorage } from '~/lib/utils/local_storage_alert';

const MR_SOURCE_BRANCH = 'merge_request[source_branch]';

/**
 * Builds the URL path for viewing a blob
 * @param {string} baseUrl - The base URL to modify
 * @param {Object} options - Options for building the path
 * @param {string} options.targetPath - The target project path
 * @param {string} options.branch - The branch name
 * @param {string} options.filePath - The file path
 * @returns {string} The constructed URL
 */
export const buildBlobViewPath = (baseUrl, options) => {
  const { targetPath, branch, filePath } = options;
  const urlObj = new URL(baseUrl);
  urlObj.pathname = joinPaths(targetPath, '-/blob', branch, filePath);
  return urlObj.toString();
};

/**
 * Redirects to an existing merge request
 * @param {Object} options - Redirect options
 * @param {string} options.url - The current URL
 * @param {string} options.projectPath - The project path
 * @param {string} options.fromMergeRequestIid - The merge request IID to redirect to
 */
export const redirectToExistingMergeRequest = ({ url, projectPath, fromMergeRequestIid }) => {
  const urlCopy = new URL(url);
  urlCopy.pathname = joinPaths(projectPath, '/-/merge_requests/', fromMergeRequestIid);
  const cleanUrl = removeParams(['from_merge_request_iid'], urlCopy.toString());
  visitUrl(cleanUrl);
};

/**
 * Redirects to create a new merge request
 * @param {Object} options - Redirect options
 * @param {string} options.newMergeRequestPath - The path to create a new merge request
 * @param {string} options.sourceBranch - The source branch for the merge request
 */
export const redirectToCreateMergeRequest = ({ newMergeRequestPath, sourceBranch }) => {
  const mrUrl = mergeUrlParams({ [MR_SOURCE_BRANCH]: sourceBranch }, newMergeRequestPath);
  visitUrl(mrUrl);
};

/**
 * Redirects to create a merge request from a fork
 * @param {Object} options - Redirect options
 * @param {string} options.url - The current URL
 * @param {string} options.targetProjectPath - The target (fork) project path
 * @param {string} options.targetProjectId - The target (fork) project ID
 * @param {string} options.sourceBranch - The source branch in the fork
 * @param {string} options.projectId - The original project ID
 * @param {string} options.originalBranch - The original branch to merge into
 */
export const redirectToForkMergeRequest = ({
  url,
  targetProjectPath,
  targetProjectId,
  sourceBranch,
  projectId,
  originalBranch,
}) => {
  const urlCopy = new URL(url);
  urlCopy.pathname = joinPaths(targetProjectPath, '/-/merge_requests/new');

  const mrParams = {
    'merge_request[source_project_id]': targetProjectId,
    'merge_request[source_branch]': sourceBranch,
    'merge_request[target_project_id]': projectId,
    'merge_request[target_branch]': originalBranch,
  };

  const finalMrUrl = mergeUrlParams(mrParams, urlCopy.toString());
  visitUrl(finalMrUrl);
};

/**
 * Redirects to the blob view with a success alert
 * @param {Object} options - Redirect options
 * @param {string} options.url - The current URL string
 * @param {string} options.resultingBranch - The branch where changes were committed
 * @param {Object} options.responseData - The API response data
 * @param {Object} options.formData - The form data submitted
 * @param {boolean} options.isNewBranch - Whether a new branch was created
 * @param {string} options.targetProjectPath - The target project path
 * @param {Function} options.successMessageFn - Function to generate the success message
 */
export const redirectToBlobWithAlert = ({
  url,
  resultingBranch,
  responseData,
  formData,
  isNewBranch,
  targetProjectPath,
  successMessageFn,
}) => {
  const cleanUrl = removeParams(['from_merge_request_iid'], url);
  const successPath = buildBlobViewPath(cleanUrl, {
    targetPath: targetProjectPath,
    branch: resultingBranch,
    filePath: responseData.file_path || formData.file_path,
  });
  const createMergeRequestNotChosen = !formData.create_merge_request;

  const message = successMessageFn(isNewBranch, createMergeRequestNotChosen);

  saveAlertToLocalStorage({
    message,
    messageLinks: { changesLink: successPath },
    variant: VARIANT_INFO,
  });

  visitUrl(successPath);
};
