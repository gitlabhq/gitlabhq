import { TEST_HOST } from 'helpers/test_constants';
import * as types from '~/error_tracking_settings/store/mutation_types';
import mutations from '~/error_tracking_settings/store/mutations';
import defaultState from '~/error_tracking_settings/store/state';
import {
  initialEmptyState,
  initialPopulatedState,
  projectList,
  sampleBackendProject,
  normalizedProject,
} from '../mock';

describe('error tracking settings mutations', () => {
  describe('mutations', () => {
    let state;

    beforeEach(() => {
      state = defaultState();
    });

    it('should create an empty initial state correctly', () => {
      mutations[types.SET_INITIAL_STATE](state, {
        ...initialEmptyState,
      });

      expect(state.apiHost).toEqual('');
      expect(state.enabled).toEqual(false);
      expect(state.integrated).toEqual(false);
      expect(state.selectedProject).toEqual(null);
      expect(state.token).toEqual('');
      expect(state.listProjectsEndpoint).toEqual(TEST_HOST);
      expect(state.operationsSettingsEndpoint).toEqual(TEST_HOST);
    });

    it('should populate the initial state correctly', () => {
      mutations[types.SET_INITIAL_STATE](state, {
        ...initialPopulatedState,
      });

      expect(state.apiHost).toEqual('apiHost');
      expect(state.enabled).toEqual(true);
      expect(state.integrated).toEqual(true);
      expect(state.selectedProject).toEqual(projectList[0]);
      expect(state.token).toEqual('token');
      expect(state.listProjectsEndpoint).toEqual(TEST_HOST);
      expect(state.operationsSettingsEndpoint).toEqual(TEST_HOST);
    });

    it('should receive projects successfully', () => {
      mutations[types.RECEIVE_PROJECTS](state, [sampleBackendProject]);

      expect(state.projects).toEqual([normalizedProject]);
    });

    it('should strip out unnecessary project properties', () => {
      mutations[types.RECEIVE_PROJECTS](state, [
        { ...sampleBackendProject, extra_property: 'extra_property' },
      ]);

      expect(state.projects).toEqual([normalizedProject]);
    });

    it('should update state when connect is successful', () => {
      mutations[types.UPDATE_CONNECT_SUCCESS](state);

      expect(state.connectSuccessful).toBe(true);
      expect(state.connectError).toBe(false);
    });

    it('should update state when connect fails', () => {
      mutations[types.UPDATE_CONNECT_ERROR](state);

      expect(state.connectSuccessful).toBe(false);
      expect(state.connectError).toBe(true);
    });

    it('should update state when connect is reset', () => {
      mutations[types.RESET_CONNECT](state);

      expect(state.connectSuccessful).toBe(false);
      expect(state.connectError).toBe(false);
    });

    it.each([true, false])('should update `integrated` to `%s`', (integrated) => {
      mutations[types.UPDATE_INTEGRATED](state, integrated);

      expect(state.integrated).toBe(integrated);
    });
  });
});
