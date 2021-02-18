import * as types from '~/ide/stores/modules/editor/mutation_types';
import mutations from '~/ide/stores/modules/editor/mutations';
import { createDefaultFileEditor } from '~/ide/stores/modules/editor/utils';
import { createTriggerRenamePayload } from '../../../helpers';

const TEST_PATH = 'test/path.md';

describe('~/ide/stores/modules/editor/mutations', () => {
  describe(types.UPDATE_FILE_EDITOR, () => {
    it('with path that does not exist, should initialize with default values', () => {
      const state = { fileEditors: {} };
      const data = { fileLanguage: 'markdown' };

      mutations[types.UPDATE_FILE_EDITOR](state, { path: TEST_PATH, data });

      expect(state.fileEditors).toEqual({
        [TEST_PATH]: {
          ...createDefaultFileEditor(),
          ...data,
        },
      });
    });

    it('with existing path, should overwrite values', () => {
      const state = {
        fileEditors: {
          foo: {},
          [TEST_PATH]: { ...createDefaultFileEditor(), editorRow: 7, editorColumn: 7 },
        },
      };

      mutations[types.UPDATE_FILE_EDITOR](state, {
        path: TEST_PATH,
        data: { fileLanguage: 'markdown' },
      });

      expect(state).toEqual({
        fileEditors: {
          foo: {},
          [TEST_PATH]: {
            ...createDefaultFileEditor(),
            editorRow: 7,
            editorColumn: 7,
            fileLanguage: 'markdown',
          },
        },
      });
    });
  });

  describe(types.REMOVE_FILE_EDITOR, () => {
    it.each`
      fileEditors                     | path                    | expected
      ${{}}                           | ${'does/not/exist.txt'} | ${{}}
      ${{ foo: {}, [TEST_PATH]: {} }} | ${TEST_PATH}            | ${{ foo: {} }}
    `('removes file $path', ({ fileEditors, path, expected }) => {
      const state = { fileEditors };

      mutations[types.REMOVE_FILE_EDITOR](state, path);

      expect(state).toEqual({ fileEditors: expected });
    });
  });

  describe(types.RENAME_FILE_EDITOR, () => {
    it.each`
      fileEditors                   | payload                                                | expected
      ${{ foo: {} }}                | ${createTriggerRenamePayload('does/not/exist', 'abc')} | ${{ foo: {} }}
      ${{ foo: { a: 1 }, bar: {} }} | ${createTriggerRenamePayload('foo', 'abc/def')}        | ${{ 'abc/def': { a: 1 }, bar: {} }}
    `('renames fileEditor at $payload', ({ fileEditors, payload, expected }) => {
      const state = { fileEditors };

      mutations[types.RENAME_FILE_EDITOR](state, payload);

      expect(state).toEqual({ fileEditors: expected });
    });
  });
});
