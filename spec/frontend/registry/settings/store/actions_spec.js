import Api from '~/api';
import createFlash from '~/flash';
import testAction from 'helpers/vuex_action_helper';
import * as actions from '~/registry/settings/store/actions';
import * as types from '~/registry/settings/store/mutation_types';
import {
  UPDATE_SETTINGS_ERROR_MESSAGE,
  FETCH_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '~/registry/settings/constants';

jest.mock('~/flash');

describe('Actions Registry Store', () => {
  describe.each`
    actionName                  | mutationName               | payload
    ${'setInitialState'}        | ${types.SET_INITIAL_STATE} | ${'foo'}
    ${'updateSettings'}         | ${types.UPDATE_SETTINGS}   | ${'foo'}
    ${'receiveSettingsSuccess'} | ${types.SET_SETTINGS}      | ${'foo'}
    ${'toggleLoading'}          | ${types.TOGGLE_LOADING}    | ${undefined}
    ${'resetSettings'}          | ${types.RESET_SETTINGS}    | ${undefined}
  `('%s action invokes %s mutation with payload %s', ({ actionName, mutationName, payload }) => {
    it('should set the initial state', done => {
      testAction(actions[actionName], payload, {}, [{ type: mutationName, payload }], [], done);
    });
  });

  describe.each`
    actionName                | message
    ${'receiveSettingsError'} | ${FETCH_SETTINGS_ERROR_MESSAGE}
    ${'updateSettingsError'}  | ${UPDATE_SETTINGS_ERROR_MESSAGE}
  `('%s action', ({ actionName, message }) => {
    it(`should call createFlash with ${message}`, done => {
      testAction(actions[actionName], null, null, [], [], () => {
        expect(createFlash).toHaveBeenCalledWith(message);
        done();
      });
    });
  });

  describe('fetchSettings', () => {
    const state = {
      projectId: 'bar',
    };

    const payload = {
      tag_expiration_policies: 'foo',
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
          { type: 'receiveSettingsSuccess', payload: payload.tag_expiration_policies },
          { type: 'toggleLoading' },
        ],
        done,
      );
    });

    it('should call receiveSettingsError on error', done => {
      Api.project = jest.fn().mockRejectedValue();
      testAction(
        actions.fetchSettings,
        null,
        state,
        [],
        [{ type: 'toggleLoading' }, { type: 'receiveSettingsError' }, { type: 'toggleLoading' }],
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
      tag_expiration_policies: 'foo',
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
          { type: 'receiveSettingsSuccess', payload: payload.tag_expiration_policies },
          { type: 'toggleLoading' },
        ],
        () => {
          expect(createFlash).toHaveBeenCalledWith(UPDATE_SETTINGS_SUCCESS_MESSAGE);
          done();
        },
      );
    });

    it('should call receiveSettingsError on error', done => {
      Api.updateProject = jest.fn().mockRejectedValue();
      testAction(
        actions.saveSettings,
        null,
        state,
        [],
        [{ type: 'toggleLoading' }, { type: 'updateSettingsError' }, { type: 'toggleLoading' }],
        done,
      );
    });
  });
});
