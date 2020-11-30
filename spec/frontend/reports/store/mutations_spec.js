import state from '~/reports/store/state';
import mutations from '~/reports/store/mutations';
import * as types from '~/reports/store/mutation_types';
import { issue } from '../mock_data/mock_data';

describe('Reports Store Mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state();
  });

  describe('SET_ENDPOINT', () => {
    it('should set endpoint', () => {
      mutations[types.SET_ENDPOINT](stateCopy, 'endpoint.json');

      expect(stateCopy.endpoint).toEqual('endpoint.json');
    });
  });

  describe('REQUEST_REPORTS', () => {
    it('should set isLoading to true', () => {
      mutations[types.REQUEST_REPORTS](stateCopy);

      expect(stateCopy.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_REPORTS_SUCCESS', () => {
    const mockedResponse = {
      summary: {
        total: 14,
        resolved: 0,
        failed: 7,
      },
      suites: [
        {
          name: 'build:linux',
          summary: {
            total: 2,
            resolved: 0,
            failed: 1,
          },
          new_failures: [
            {
              name: 'StringHelper#concatenate when a is git and b is lab returns summary',
              execution_time: 0.0092435,
              system_output: "Failure/Error: is_expected.to eq('gitlab')",
              recent_failures: {
                count: 4,
                base_branch: 'master',
              },
            },
          ],
          resolved_failures: [
            {
              name: 'StringHelper#concatenate when a is git and b is lab returns summary',
              execution_time: 0.009235,
              system_output: "Failure/Error: is_expected.to eq('gitlab')",
            },
          ],
          existing_failures: [
            {
              name: 'StringHelper#concatenate when a is git and b is lab returns summary',
              execution_time: 1232.08,
              system_output: "Failure/Error: is_expected.to eq('gitlab')",
            },
          ],
        },
      ],
    };

    beforeEach(() => {
      mutations[types.RECEIVE_REPORTS_SUCCESS](stateCopy, mockedResponse);
    });

    it('should reset isLoading', () => {
      expect(stateCopy.isLoading).toEqual(false);
    });

    it('should reset hasError', () => {
      expect(stateCopy.hasError).toEqual(false);
    });

    it('should set summary counts', () => {
      expect(stateCopy.summary.total).toEqual(mockedResponse.summary.total);
      expect(stateCopy.summary.resolved).toEqual(mockedResponse.summary.resolved);
      expect(stateCopy.summary.failed).toEqual(mockedResponse.summary.failed);
      expect(stateCopy.summary.recentlyFailed).toEqual(1);
    });

    it('should set reports', () => {
      expect(stateCopy.reports).toEqual(mockedResponse.suites);
    });
  });

  describe('RECEIVE_REPORTS_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_REPORTS_ERROR](stateCopy);
    });

    it('should reset isLoading', () => {
      expect(stateCopy.isLoading).toEqual(false);
    });

    it('should set hasError to true', () => {
      expect(stateCopy.hasError).toEqual(true);
    });

    it('should reset reports', () => {
      expect(stateCopy.reports).toEqual([]);
    });
  });

  describe('SET_ISSUE_MODAL_DATA', () => {
    beforeEach(() => {
      mutations[types.SET_ISSUE_MODAL_DATA](stateCopy, {
        issue,
      });
    });

    it('should set modal title', () => {
      expect(stateCopy.modal.title).toEqual(issue.name);
    });

    it('should set modal data', () => {
      expect(stateCopy.modal.data.execution_time.value).toEqual(issue.execution_time);
      expect(stateCopy.modal.data.system_output.value).toEqual(issue.system_output);
    });
  });
});
