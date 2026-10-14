import { joinPaths, escapeFileUrl } from '~/lib/utils/url_utility';

/**
 * Builds the "browse files at this commit" URL.
 *
 * With a current path it links to the blob view; a blob URL pointing at a
 * directory redirects to the tree view server-side, so one URL shape covers
 * files and directories. Without a path it links to the repository root tree.
 *
 * @param {Object} options
 * @param {string} options.projectRootPath - Root path of the project
 * @param {string} options.commitSha - SHA of the commit to browse at
 * @param {string} [options.currentPath] - File or directory path being viewed
 * @returns {string} URL to browse files at the given commit
 */
export function getBrowseFilesPath({ projectRootPath, commitSha, currentPath }) {
  if (currentPath) {
    return joinPaths(projectRootPath, '-', 'blob', commitSha, escapeFileUrl(currentPath));
  }
  return joinPaths(projectRootPath, '-', 'tree', commitSha);
}
