import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/ide/stores/modules/router/actions';
import * as types from '~/ide/stores/modules/router/mutation_types';

const TEST_PATH = 'test/path/abc';

describe('ide/stores/modules/router/actions', () => {
  describe('push', () => {
    it('commits mutation', () => {
      return testAction(
        actions.push,
        TEST_PATH,
        {},
        [{ type: types.PUSH, payload: TEST_PATH }],
        [],
      );
    });
  });
});
