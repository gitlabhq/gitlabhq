import { joinPaths } from '~/lib/utils/url_utility';

/**
 * Matches the namespace and target directory/blob in a path
 * Example: /root/Flight/-/blob/fix/main/test/spec/utils_spec.js
 * Group 1:  /-/blob
 * Group 2:  blob
 * Group 3:  main/test/spec/utils_spec.js
 */
const NAMESPACE_TARGET_REGEX = /(\/-\/(blob|tree))\/.*?\/(.*)/;

/**
 * Generates a ref destination path based on the selected ref and current path.
 * A user could either be in the project root, a directory on the blob view.
 * @param {string} projectRootPath - The root path for a project.
 * @param {string} selectedRef - The selected ref from the ref dropdown.
 */
export function generateRefDestinationPath(projectRootPath, selectedRef) {
  const currentPath = window.location.pathname;
  let namespace = '/-/tree';
  let target;
  const match = NAMESPACE_TARGET_REGEX.exec(currentPath);
  if (match) {
    [, namespace, , target] = match;
  }

  const destinationPath = joinPaths(projectRootPath, namespace, selectedRef, target);

  return `${destinationPath}${window.location.hash}`;
}
