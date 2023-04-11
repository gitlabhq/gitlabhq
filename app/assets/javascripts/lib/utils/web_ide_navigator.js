import { visitUrl, webIDEUrl } from '~/lib/utils/url_utility';

/**
 * Takes a project path and optional file path and branch
 * and then redirects the user to the web IDE.
 *
 * @param {string} projectPath - Full path to project including namespace (ex. flightjs/Flight)
 * @param {string} filePath - optional path to file to be edited, otherwise will open at base directory (ex. README.md)
 * @param {string} branch - optional branch to open the IDE, defaults to 'main'
 */

export const openWebIDE = (projectPath, filePath, branch = 'main') => {
  if (!projectPath) {
    throw new TypeError('projectPath parameter is required');
  }

  const pathnameSegments = [projectPath, 'edit', branch, '-'];

  if (filePath) {
    pathnameSegments.push(filePath);
  }

  visitUrl(webIDEUrl(`/${pathnameSegments.join('/')}/`));
};
