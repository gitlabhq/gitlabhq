import { trace, showAdvancedFilters } from '~/logs/stores/getters';
import logsPageState from '~/logs/stores/state';

import { mockLogsResult, mockTrace, mockEnvName, mockEnvironments } from '../mock_data';

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
});
