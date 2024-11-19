import { joinPaths } from '~/lib/utils/url_utility';

/**
 * Matches the namespace and target directory/blob in a path
 * Example: /root/Flight/-/blob/fix/main/test/spec/utils_spec.js
 * Group 1:  /-/blob
 * Group 2:  blob
 * Group 3: /test/spec/utils_spec.js
 */
const getNamespaceTargetRegex = (ref) => new RegExp(`(/-/(blob|tree))/${ref}/(.*)`);

/**
 * Generates a ref destination path based on the selected ref and current path.
 * A user could either be in the project root, a directory on the blob view.
 * @param {string} projectRootPath - The root path for a project.
 * @param {string} selectedRef - The selected ref from the ref dropdown.
 */
export function generateRefDestinationPath(projectRootPath, ref, selectedRef) {
  const url = new URL(window.location.href);
  const currentPath = url.pathname;
  const encodedHash = '%23';
  let refType = null;
  let namespace = '/-/tree';
  let target;
  let actualRef = selectedRef;

  const matches = selectedRef.match(/^refs\/(heads|tags)\/(.+)/);
  if (matches) {
    [, refType, actualRef] = matches;
  }
  if (refType) {
    url.searchParams.set('ref_type', refType.toLowerCase());
  } else {
    url.searchParams.delete('ref_type');
  }

  const NAMESPACE_TARGET_REGEX = getNamespaceTargetRegex(ref);
  const match = NAMESPACE_TARGET_REGEX.exec(currentPath);
  if (match) {
    [, namespace, , target] = match;
  }
  url.pathname = joinPaths(
    projectRootPath,
    namespace,
    encodeURI(actualRef).replace(/#/g, encodedHash),
    target,
  );

  return url.toString();
}
