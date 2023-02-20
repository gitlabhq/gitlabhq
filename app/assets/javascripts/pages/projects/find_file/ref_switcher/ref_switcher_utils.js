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

  const { pathname } = window.location;
  const encodedHash = '%23';

  const [projectRootPath] = pathname.split(namespace);

  const destinationPath = joinPaths(
    projectRootPath,
    namespace,
    encodeURI(selectedRef).replace(/#/g, encodedHash),
  );

  const newURL = new URL(window.location);
  newURL.pathname = destinationPath;

  return newURL.href;
}
