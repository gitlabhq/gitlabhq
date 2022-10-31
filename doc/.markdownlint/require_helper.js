/**
 * Look up the global node modules directory.
 *
 * Because we install markdownlint packages globally
 * in the Docker image where this runs, we need to
 * provide the path to the global install location
 * when referencing global functions from our own node
 * modules.
 *
 * Image:
 * https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/dockerfiles/gitlab-docs-lint-markdown.Dockerfile
 */
const { execSync } = require('child_process');
module.exports.globalPath = execSync('yarn global dir').toString().trim() + '/node_modules/';
