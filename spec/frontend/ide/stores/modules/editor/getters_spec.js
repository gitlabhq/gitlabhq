import * as getters from '~/ide/stores/modules/editor/getters';
import { createDefaultFileEditor } from '~/ide/stores/modules/editor/utils';

const TEST_PATH = 'test/path.md';
const TEST_FILE_EDITOR = {
  ...createDefaultFileEditor(),
  editorRow: 7,
  editorColumn: 8,
  fileLanguage: 'markdown',
};

describe('~/ide/stores/modules/editor/getters', () => {
  describe('activeFileEditor', () => {
    it.each`
      activeFile             | fileEditors                                                            | expected
      ${null}                | ${{}}                                                                  | ${null}
      ${{}}                  | ${{}}                                                                  | ${createDefaultFileEditor()}
      ${{ path: TEST_PATH }} | ${{}}                                                                  | ${createDefaultFileEditor()}
      ${{ path: TEST_PATH }} | ${{ bogus: createDefaultFileEditor(), [TEST_PATH]: TEST_FILE_EDITOR }} | ${TEST_FILE_EDITOR}
    `(
      'with activeFile=$activeFile and fileEditors=$fileEditors',
      ({ activeFile, fileEditors, expected }) => {
        const rootGetters = { activeFile };
        const state = { fileEditors };
        const result = getters.activeFileEditor(state, {}, {}, rootGetters);

        expect(result).toEqual(expected);
      },
    );
  });
});
