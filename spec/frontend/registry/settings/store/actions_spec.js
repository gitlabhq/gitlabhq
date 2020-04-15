import Api from '~/api';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/registry/settings/store/actions';
import * as types from '~/registry/settings/store/mutation_types';

describe('Actions Registry Store', () => {
  describe.each`
    actionName           | mutationName               | payload
    ${'setInitialState'} | ${types.SET_INITIAL_STATE} | ${'foo'}
    ${'updateSettings'}  | ${types.UPDATE_SETTINGS}   | ${'foo'}
    ${'toggleLoading'}   | ${types.TOGGLE_LOADING}    | ${undefined}
    ${'resetSettings'}   | ${types.RESET_SETTINGS}    | ${undefined}
  `(
    '$actionName invokes $mutationName with payload $payload',
    ({ actionName, mutationName, payload }) => {
      it('should set state', done => {
        testAction(actions[actionName], payload, {}, [{ type: mutationName, payload }], [], done);
      });
    },
  );

  describe('receiveSettingsSuccess', () => {
    it('calls SET_SETTINGS', () => {
      testAction(
        actions.receiveSettingsSuccess,
        'foo',
        {},
        [{ type: types.SET_SETTINGS, payload: 'foo' }],
        [],
      );
    });
  });

  describe('fetchSettings', () => {
    const state = {
      projectId: 'bar',
    };

    const payload = {
      data: {
        container_expiration_policy: 'foo',
      },
    };

    it('should fetch the data from the API', done => {
      Api.project = jest.fn().mockResolvedValue(payload);
      testAction(
        actions.fetchSettings,
        null,
        state,
        [],
        [
          { type: 'toggleLoading' },
          { type: 'receiveSettingsSuccess', payload: payload.data.container_expiration_policy },
          { type: 'toggleLoading' },
        ],
        done,
      );
    });
  });

  describe('saveSettings', () => {
    const state = {
      projectId: 'bar',
      settings: 'baz',
    };

    const payload = {
      data: {
        tag_expiration_policies: 'foo',
      },
    };

    it('should fetch the data from the API', done => {
      Api.updateProject = jest.fn().mockResolvedValue(payload);
      testAction(
        actions.saveSettings,
        null,
        state,
        [],
        [
          { type: 'toggleLoading' },
          { type: 'receiveSettingsSuccess', payload: payload.data.container_expiration_policy },
          { type: 'toggleLoading' },
        ],
        done,
      );
    });
  });
});
