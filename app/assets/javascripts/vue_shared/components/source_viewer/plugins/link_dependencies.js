import packageJsonLinker from './utils/package_json_linker';
import gemspecLinker from './utils/gemspec_linker';
import godepsJsonLinker from './utils/godeps_json_linker';
import gemfileLinker from './utils/gemfile_linker';
import podspecJsonLinker from './utils/podspec_json_linker';
import composerJsonLinker from './utils/composer_json_linker';
import goSumLinker from './utils/go_sum_linker';

const DEPENDENCY_LINKERS = {
  package_json: packageJsonLinker,
  gemspec: gemspecLinker,
  godeps_json: godepsJsonLinker,
  gemfile: gemfileLinker,
  podspec_json: podspecJsonLinker,
  composer_json: composerJsonLinker,
  go_sum: goSumLinker,
};

/**
 * Highlight.js plugin for generating links to dependencies when viewing dependency files.
 *
 * Plugin API: https://github.com/highlightjs/highlight.js/blob/main/docs/plugin-api.rst
 *
 * @param {Object} result - an object that represents the highlighted result from Highlight.js
 * @param {String} fileType - a string containing the file type
 * @param {String} rawContent - raw (non-highlighted) file content
 */
export default (result, fileType, rawContent) => {
  if (DEPENDENCY_LINKERS[fileType]) {
    try {
      // eslint-disable-next-line no-param-reassign
      result.value = DEPENDENCY_LINKERS[fileType](result, rawContent);
    } catch (e) {
      // Shallowed (do nothing), in this case the original unlinked dependencies will be rendered.
    }
  }
};
