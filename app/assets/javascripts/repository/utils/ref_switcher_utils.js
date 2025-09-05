import { joinPaths } from '~/lib/utils/url_utility';

/**
 * Creates a regex pattern to extract namespace and target path information from repository URLs.
 *
 * @param {string} ref - The git reference (branch name, tag, or commit SHA) to match in the URL
 * @returns {RegExp} A regex pattern that captures GitLab URL components
 *
 * Capture groups:
 * - Group 1: The namespace format (e.g., "/-/blob", "/-/tree", "/-/commits", "/blob")
 * - Group 2: The view type ("blob", "tree", or "commits")
 * - Group 3: The target path after the ref (file/directory path, can be empty string)
 *
 * Supports:
 * - Standard GitLab namespace formats: /-/blob, /-/tree, /-/commits
 * - Alternative blob format: /blob
 * - URLs ending with ref only (optional trailing slash)
 * - Partial URL matching (no end anchor)
 *
 */
const getNamespaceTargetRegex = (ref) => new RegExp(`(/-/(blob|tree|commits)|/blob)/${ref}/?(.*)`);

/**
 * Parses a selected ref and generates router navigation parameters for Vue Router.
 * Handles symbolic refs (refs/heads/*, refs/tags/*) and URL encoding.
 *
 * @param {string} selectedRef - The selected ref from the ref dropdown.
 * @param {Object} currentRoute - The current Vue Router route object.
 * @returns {Object} Object containing path and query for router navigation.
 */
export function generateRouterParams(selectedRef, currentRoute) {
  const encodedHash = '%23';

  const matches = selectedRef.match(/^refs\/(heads|tags)\/(.+)/) || [];
  const [, refType = null, actualRef = selectedRef] = matches;

  const query = { ...currentRoute.query };
  if (refType) {
    query.ref_type = refType.toLowerCase();
  } else {
    delete query.ref_type;
  }

  const encodedRef = encodeURI(actualRef).replace(/#/g, encodedHash);
  const path = `/${encodedRef}/${currentRoute.params.path || ''}`;

  return { path, query };
}

/**
 * Generates a ref destination path based on the selected ref and current path.
 * A user could either be in the project root, a directory on the blob view, or commits view.
 * @param {string} projectRootPath - The root path for a project.
 * @param {string} ref - The current ref.
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
