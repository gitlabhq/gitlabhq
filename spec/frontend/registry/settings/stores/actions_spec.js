import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/registry/settings/stores/actions';
import * as types from '~/registry/settings/stores/mutation_types';

jest.mock('~/flash.js');

describe('Actions Registry Store', () => {
  describe('setInitialState', () => {
    it('should set the initial state', done => {
      testAction(
        actions.setInitialState,
        'foo',
        {},
        [{ type: types.SET_INITIAL_STATE, payload: 'foo' }],
        [],
        done,
      );
    });
  });
});
