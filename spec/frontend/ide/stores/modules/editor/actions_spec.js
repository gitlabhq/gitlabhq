import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/ide/stores/modules/editor/actions';
import * as types from '~/ide/stores/modules/editor/mutation_types';
import { createTriggerRenamePayload } from '../../../helpers';

describe('~/ide/stores/modules/editor/actions', () => {
  describe('updateFileEditor', () => {
    it('commits with payload', () => {
      const payload = {};

      return testAction(actions.updateFileEditor, payload, {}, [
        { type: types.UPDATE_FILE_EDITOR, payload },
      ]);
    });
  });

  describe('removeFileEditor', () => {
    it('commits with payload', () => {
      const payload = 'path/to/file.txt';

      return testAction(actions.removeFileEditor, payload, {}, [
        { type: types.REMOVE_FILE_EDITOR, payload },
      ]);
    });
  });

  describe('renameFileEditor', () => {
    it('commits with payload', () => {
      const payload = createTriggerRenamePayload('test', 'test123');

      return testAction(actions.renameFileEditor, payload, {}, [
        { type: types.RENAME_FILE_EDITOR, payload },
      ]);
    });
  });
});
