import packageJsonLinker from '~/highlight_js/plugins/utils/package_json_linker';
import godepsJsonLinker from '~/highlight_js/plugins/utils/godeps_json_linker';
import gemspecLinker from '~/highlight_js/plugins/utils/gemspec_linker';
import gemfileLinker from '~/highlight_js/plugins/utils/gemfile_linker';
import podspecJsonLinker from '~/highlight_js/plugins/utils/podspec_json_linker';
import composerJsonLinker from '~/highlight_js/plugins/utils/composer_json_linker';
import goSumLinker from '~/highlight_js/plugins/utils/go_sum_linker';
import linkDependencies from '~/highlight_js/plugins/link_dependencies';
import {
  PACKAGE_JSON_FILE_TYPE,
  GEMSPEC_FILE_TYPE,
  GODEPS_JSON_FILE_TYPE,
  GEMFILE_FILE_TYPE,
  PODSPEC_JSON_FILE_TYPE,
  COMPOSER_JSON_FILE_TYPE,
  GO_SUM_FILE_TYPE,
} from './mock_data';

jest.mock('~/highlight_js/plugins/utils/package_json_linker');
jest.mock('~/highlight_js/plugins/utils/gemspec_linker');
jest.mock('~/highlight_js/plugins/utils/godeps_json_linker');
jest.mock('~/highlight_js/plugins/utils/gemfile_linker');
jest.mock('~/highlight_js/plugins/utils/podspec_json_linker');
jest.mock('~/highlight_js/plugins/utils/composer_json_linker');
jest.mock('~/highlight_js/plugins/utils/go_sum_linker');

describe('Highlight.js plugin for linking dependencies', () => {
  const hljsResultMock = { value: 'test' };

  describe.each`
    fileType                   | linker
    ${PACKAGE_JSON_FILE_TYPE}  | ${packageJsonLinker}
    ${GEMSPEC_FILE_TYPE}       | ${gemspecLinker}
    ${GODEPS_JSON_FILE_TYPE}   | ${godepsJsonLinker}
    ${GEMFILE_FILE_TYPE}       | ${gemfileLinker}
    ${PODSPEC_JSON_FILE_TYPE}  | ${podspecJsonLinker}
    ${COMPOSER_JSON_FILE_TYPE} | ${composerJsonLinker}
    ${GO_SUM_FILE_TYPE}        | ${goSumLinker}
  `('$fileType file type', ({ fileType, linker }) => {
    it('calls the correct linker', () => {
      linkDependencies(hljsResultMock, fileType);
      expect(linker).toHaveBeenCalled();
    });

    it('does not call the linker for non-matching file types', () => {
      const unknownFileType = 'unknown';

      linkDependencies(hljsResultMock, unknownFileType);
      expect(linker).not.toHaveBeenCalled();
    });
  });
});
