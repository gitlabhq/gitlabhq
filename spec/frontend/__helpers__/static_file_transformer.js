/* eslint-disable import/no-commonjs */

/**
 * Jest transformer for static asset imports (svg/gif/png/mp4).
 *
 * Emits a mock value derived from the asset's filename so assertions like
 * `toBe(SOME_ILLUSTRATION)` verify the expected file, instead of comparing two
 * identical `file-mock` strings.
 *
 * Example:
 *   @gitlab/svgs/dist/illustrations/empty-state/empty-devops-md.svg
 *   => 'file-mock-empty-devops-md.svg'
 */
const path = require('path');

module.exports = {
  process(_src, filename) {
    const value = `file-mock-${path.basename(filename.split('?')[0])}`;
    return { code: `module.exports = ${JSON.stringify(value)};` };
  },
};
