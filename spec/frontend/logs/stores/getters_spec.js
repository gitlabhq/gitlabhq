import { trace, showAdvancedFilters } from '~/logs/stores/getters';
import logsPageState from '~/logs/stores/state';

import {
  mockLogsResult,
  mockTrace,
  mockEnvName,
  mockEnvironments,
  mockManagedApps,
  mockManagedAppName,
} from '../mock_data';

describe('Logs Store getters', () => {
  let state;

  beforeEach(() => {
    state = logsPageState();
  });

  describe('trace', () => {
    describe('when state is initialized', () => {
      it('returns an empty string', () => {
        expect(trace(state)).toEqual('');
      });
    });

    describe('when state logs are empty', () => {
      beforeEach(() => {
        state.logs.lines = [];
      });

      it('returns an empty string', () => {
        expect(trace(state)).toEqual('');
      });
    });

    describe('when state logs are set', () => {
      beforeEach(() => {
        state.logs.lines = mockLogsResult;
      });

      it('returns an empty string', () => {
        expect(trace(state)).toEqual(mockTrace.join('\n'));
      });
    });
  });

  describe('showAdvancedFilters', () => {
    describe('when no environments are set', () => {
      beforeEach(() => {
        state.environments.current = mockEnvName;
        state.environments.options = [];
      });

      it('returns false', () => {
        expect(showAdvancedFilters(state)).toBe(false);
      });
    });

    describe('when the environment supports filters', () => {
      beforeEach(() => {
        state.environments.current = mockEnvName;
        state.environments.options = mockEnvironments;
      });

      it('returns true', () => {
        expect(showAdvancedFilters(state)).toBe(true);
      });
    });

    describe('when the environment does not support filters', () => {
      beforeEach(() => {
        state.environments.options = mockEnvironments;
        state.environments.current = mockEnvironments[1].name;
      });

      it('returns true', () => {
        expect(showAdvancedFilters(state)).toBe(false);
      });
    });
  });

  describe('when no managedApps are set', () => {
    beforeEach(() => {
      state.environments.current = null;
      state.environments.options = [];
      state.managedApps.current = mockManagedAppName;
      state.managedApps.options = [];
    });

    it('returns false', () => {
      expect(showAdvancedFilters(state)).toBe(false);
    });
  });

  describe('when the managedApp supports filters', () => {
    beforeEach(() => {
      state.environments.current = null;
      state.environments.options = mockEnvironments;
      state.managedApps.current = mockManagedAppName;
      state.managedApps.options = mockManagedApps;
    });

    it('returns true', () => {
      expect(showAdvancedFilters(state)).toBe(true);
    });
  });

  describe('when the managedApp does not support filters', () => {
    beforeEach(() => {
      state.environments.current = null;
      state.environments.options = mockEnvironments;
      state.managedApps.options = mockManagedApps;
      state.managedApps.current = mockManagedApps[1].name;
    });

    it('returns false', () => {
      expect(showAdvancedFilters(state)).toBe(false);
    });
  });
});
