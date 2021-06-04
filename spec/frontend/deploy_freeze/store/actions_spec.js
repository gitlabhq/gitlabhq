import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import * as actions from '~/deploy_freeze/store/actions';
import * as types from '~/deploy_freeze/store/mutation_types';
import getInitialState from '~/deploy_freeze/store/state';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { freezePeriodsFixture, timezoneDataFixture } from '../helpers';

jest.mock('~/api.js');
jest.mock('~/flash.js');

describe('deploy freeze store actions', () => {
  let mock;
  let state;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    state = getInitialState({
      projectId: '8',
      timezoneData: timezoneDataFixture,
    });
    Api.freezePeriods.mockResolvedValue({ data: freezePeriodsFixture });
    Api.createFreezePeriod.mockResolvedValue();
    Api.updateFreezePeriod.mockResolvedValue();
  });

  afterEach(() => {
    mock.restore();
  });

  describe('setSelectedFreezePeriod', () => {
    it('commits SET_SELECTED_TIMEZONE mutation', () => {
      testAction(
        actions.setFreezePeriod,
        {
          id: 3,
          cronTimezone: 'UTC',
          freezeStart: 'start',
          freezeEnd: 'end',
        },
        {},
        [
          {
            payload: 3,
            type: types.SET_SELECTED_ID,
          },
          {
            payload: 'UTC',
            type: types.SET_SELECTED_TIMEZONE,
          },
          {
            payload: 'start',
            type: types.SET_FREEZE_START_CRON,
          },
          {
            payload: 'end',
            type: types.SET_FREEZE_END_CRON,
          },
        ],
      );
    });
  });

  describe('setSelectedTimezone', () => {
    it('commits SET_SELECTED_TIMEZONE mutation', () => {
      testAction(actions.setSelectedTimezone, {}, {}, [
        {
          payload: {},
          type: types.SET_SELECTED_TIMEZONE,
        },
      ]);
    });
  });

  describe('setFreezeStartCron', () => {
    it('commits SET_FREEZE_START_CRON mutation', () => {
      testAction(actions.setFreezeStartCron, {}, {}, [
        {
          type: types.SET_FREEZE_START_CRON,
        },
      ]);
    });
  });

  describe('setFreezeEndCron', () => {
    it('commits SET_FREEZE_END_CRON mutation', () => {
      testAction(actions.setFreezeEndCron, {}, {}, [
        {
          type: types.SET_FREEZE_END_CRON,
        },
      ]);
    });
  });

  describe('addFreezePeriod', () => {
    it('dispatch correct actions on adding a freeze period', () => {
      testAction(
        actions.addFreezePeriod,
        {},
        state,
        [{ type: 'RESET_MODAL' }],
        [
          { type: 'requestFreezePeriod' },
          { type: 'receiveFreezePeriodSuccess' },
          { type: 'fetchFreezePeriods' },
        ],
        () =>
          expect(Api.createFreezePeriod).toHaveBeenCalledWith(state.projectId, {
            freeze_start: state.freezeStartCron,
            freeze_end: state.freezeEndCron,
            cron_timezone: state.selectedTimezoneIdentifier,
          }),
      );
    });

    it('should show flash error and set error in state on add failure', () => {
      Api.createFreezePeriod.mockRejectedValue();

      testAction(
        actions.addFreezePeriod,
        {},
        state,
        [],
        [{ type: 'requestFreezePeriod' }, { type: 'receiveFreezePeriodError' }],
        () => expect(createFlash).toHaveBeenCalled(),
      );
    });
  });

  describe('updateFreezePeriod', () => {
    it('dispatch correct actions on updating a freeze period', () => {
      testAction(
        actions.updateFreezePeriod,
        {},
        state,
        [{ type: 'RESET_MODAL' }],
        [
          { type: 'requestFreezePeriod' },
          { type: 'receiveFreezePeriodSuccess' },
          { type: 'fetchFreezePeriods' },
        ],
        () =>
          expect(Api.updateFreezePeriod).toHaveBeenCalledWith(state.projectId, {
            id: state.selectedId,
            freeze_start: state.freezeStartCron,
            freeze_end: state.freezeEndCron,
            cron_timezone: state.selectedTimezoneIdentifier,
          }),
      );
    });

    it('should show flash error and set error in state on add failure', () => {
      Api.updateFreezePeriod.mockRejectedValue();

      testAction(
        actions.updateFreezePeriod,
        {},
        state,
        [],
        [{ type: 'requestFreezePeriod' }, { type: 'receiveFreezePeriodError' }],
        () => expect(createFlash).toHaveBeenCalled(),
      );
    });
  });

  describe('fetchFreezePeriods', () => {
    it('dispatch correct actions on fetchFreezePeriods', () => {
      testAction(
        actions.fetchFreezePeriods,
        {},
        state,
        [
          { type: types.REQUEST_FREEZE_PERIODS },
          { type: types.RECEIVE_FREEZE_PERIODS_SUCCESS, payload: freezePeriodsFixture },
        ],
        [],
      );
    });

    it('should show flash error and set error in state on fetch variables failure', () => {
      Api.freezePeriods.mockRejectedValue();

      testAction(
        actions.fetchFreezePeriods,
        {},
        state,
        [{ type: types.REQUEST_FREEZE_PERIODS }],
        [],
        () =>
          expect(createFlash).toHaveBeenCalledWith({
            message: 'There was an error fetching the deploy freezes.',
          }),
      );
    });
  });
});
