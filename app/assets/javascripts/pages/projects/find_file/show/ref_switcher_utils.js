import { joinPaths } from '~/lib/utils/url_utility';

/**
 * Generates a ref destination url based on the selected ref and current url.
 * @param {string} selectedRef - The selected ref from the ref dropdown.
 * @param {string} namespace - The destination namespace for the path.
 */
export function generateRefDestinationPath(selectedRef, namespace) {
  if (!selectedRef || !namespace) {
    return window.location.href;
  }

  let refType = null;
  const { pathname } = window.location;
  const encodedHash = '%23';

  const [projectRootPath] = pathname.split(namespace);
  let actualRef = selectedRef;

  const matches = selectedRef.match(/^refs\/(heads|tags)\/(.+)/);
  if (matches) {
    [, refType, actualRef] = matches;
  }

  const destinationPath = joinPaths(
    projectRootPath,
    namespace,
    encodeURI(actualRef).replace(/#/g, encodedHash),
  );

  const newURL = new URL(window.location);
  newURL.pathname = destinationPath;

  if (refType) {
    newURL.searchParams.set('ref_type', refType.toLowerCase());
  } else {
    newURL.searchParams.delete('ref_type');
  }

  return newURL.href;
}
