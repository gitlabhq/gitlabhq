import {
  generateServicePortsString,
  getDeploymentsStatuses,
  getDaemonSetStatuses,
  getStatefulSetStatuses,
  getReplicaSetStatuses,
  getJobsStatuses,
  getCronJobsStatuses,
  humanizeClusterErrors,
} from '~/environments/helpers/k8s_integration_helper';

import { CLUSTER_AGENT_ERROR_MESSAGES } from '~/environments/constants';

describe('k8s_integration_helper', () => {
  describe('generateServicePortsString', () => {
    const port = '8080';
    const protocol = 'TCP';
    const nodePort = '31732';

    it('returns empty string if no ports provided', () => {
      expect(generateServicePortsString([])).toBe('');
    });

    it('returns port and protocol when provided', () => {
      expect(generateServicePortsString([{ port, protocol }])).toBe(`${port}/${protocol}`);
    });

    it('returns port, protocol and nodePort when provided', () => {
      expect(generateServicePortsString([{ port, protocol, nodePort }])).toBe(
        `${port}:${nodePort}/${protocol}`,
      );
    });

    it('returns joined strings of ports if multiple are provided', () => {
      expect(
        generateServicePortsString([
          { port, protocol },
          { port, protocol, nodePort },
        ]),
      ).toBe(`${port}/${protocol}, ${port}:${nodePort}/${protocol}`);
    });
  });

  describe('getDeploymentsStatuses', () => {
    const pending = {
      status: {
        conditions: [
          { type: 'Available', status: 'False' },
          { type: 'Progressing', status: 'True' },
        ],
      },
    };
    const ready = {
      status: {
        conditions: [
          { type: 'Available', status: 'True' },
          { type: 'Progressing', status: 'False' },
        ],
      },
    };
    const failed = {
      status: {
        conditions: [
          { type: 'Available', status: 'False' },
          { type: 'Progressing', status: 'False' },
        ],
      },
    };

    it.each`
      condition                              | items                              | expected
      ${'there are only pending items'}      | ${[pending]}                       | ${{ pending: [pending] }}
      ${'there are pending and ready items'} | ${[pending, ready]}                | ${{ pending: [pending], ready: [ready] }}
      ${'there are all kind of items'}       | ${[failed, ready, ready, pending]} | ${{ pending: [pending], failed: [failed], ready: [ready, ready] }}
    `('returns correct object of statuses when $condition', ({ items, expected }) => {
      expect(getDeploymentsStatuses(items)).toEqual(expected);
    });
  });

  describe('getDaemonSetStatuses', () => {
    const ready = {
      status: {
        numberMisscheduled: 0,
        numberReady: 1,
        desiredNumberScheduled: 1,
      },
    };
    const failed = {
      status: {
        numberReady: 0,
        desiredNumberScheduled: 1,
      },
    };
    const anotherFailed = {
      status: {
        numberReady: 0,
        desiredNumberScheduled: 0,
        numberMisscheduled: 1,
      },
    };

    it.each`
      condition                        | items                             | expected
      ${'there are only failed items'} | ${[failed, anotherFailed]}        | ${{ failed: [failed, anotherFailed] }}
      ${'there are only ready items'}  | ${[ready]}                        | ${{ ready: [ready] }}
      ${'there are all kind of items'} | ${[failed, ready, anotherFailed]} | ${{ failed: [failed, anotherFailed], ready: [ready] }}
    `('returns correct object of statuses when $condition', ({ items, expected }) => {
      expect(getDaemonSetStatuses(items)).toEqual(expected);
    });
  });

  describe('getStatefulSetStatuses', () => {
    const ready = {
      status: {
        readyReplicas: 1,
      },
      spec: { replicas: 1 },
    };
    const failed = {
      status: {
        readyReplicas: 1,
      },
      spec: { replicas: 3 },
    };

    it.each`
      condition                        | items                      | expected
      ${'there are only failed items'} | ${[failed, failed]}        | ${{ failed: [failed, failed] }}
      ${'there are only ready items'}  | ${[ready]}                 | ${{ ready: [ready] }}
      ${'there are all kind of items'} | ${[failed, failed, ready]} | ${{ failed: [failed, failed], ready: [ready] }}
    `('returns correct object of statuses when $condition', ({ items, expected }) => {
      expect(getStatefulSetStatuses(items)).toEqual(expected);
    });
  });

  describe('getReplicaSetStatuses', () => {
    const ready = {
      status: {
        readyReplicas: 1,
      },
      spec: { replicas: 1 },
    };
    const failed = {
      status: {
        readyReplicas: 1,
      },
      spec: { replicas: 3 },
    };

    it.each`
      condition                        | items                      | expected
      ${'there are only failed items'} | ${[failed, failed]}        | ${{ failed: [failed, failed] }}
      ${'there are only ready items'}  | ${[ready]}                 | ${{ ready: [ready] }}
      ${'there are all kind of items'} | ${[failed, failed, ready]} | ${{ failed: [failed, failed], ready: [ready] }}
    `('returns correct object of statuses when $condition', ({ items, expected }) => {
      expect(getReplicaSetStatuses(items)).toEqual(expected);
    });
  });

  describe('getJobsStatuses', () => {
    const completed = {
      status: {
        succeeded: 1,
      },
      spec: { completions: 1 },
    };
    const failed = {
      status: {
        failed: 1,
      },
      spec: { completions: 2 },
    };

    const anotherFailed = {
      status: {
        succeeded: 1,
      },
      spec: { completions: 2 },
    };

    it.each`
      condition                           | items                                 | expected
      ${'there are only failed items'}    | ${[failed, anotherFailed]}            | ${{ failed: [failed, anotherFailed] }}
      ${'there are only completed items'} | ${[completed]}                        | ${{ completed: [completed] }}
      ${'there are all kind of items'}    | ${[failed, completed, anotherFailed]} | ${{ failed: [failed, anotherFailed], completed: [completed] }}
    `('returns correct object of statuses when $condition', ({ items, expected }) => {
      expect(getJobsStatuses(items)).toEqual(expected);
    });
  });

  describe('getCronJobsStatuses', () => {
    const suspended = {
      spec: { suspend: true },
    };
    const ready = {
      status: {
        active: 2,
        lastScheduleTime: new Date(),
      },
    };
    const failed = {
      status: {
        active: 2,
      },
    };

    it.each`
      condition                                | items                                | expected
      ${'there are only suspended items'}      | ${[suspended]}                       | ${{ suspended: [suspended] }}
      ${'there are suspended and ready items'} | ${[suspended, ready]}                | ${{ suspended: [suspended], ready: [ready] }}
      ${'there are all kind of items'}         | ${[failed, ready, ready, suspended]} | ${{ suspended: [suspended], failed: [failed], ready: [ready, ready] }}
    `('returns correct object of statuses when $condition', ({ items, expected }) => {
      expect(getCronJobsStatuses(items)).toEqual(expected);
    });
  });

  describe('humanizeClusterErrors', () => {
    it.each(['unauthorized', 'forbidden', 'not found', 'other'])(
      'returns correct object of statuses when error reason is %s',
      (reason) => {
        expect(humanizeClusterErrors(reason)).toEqual(CLUSTER_AGENT_ERROR_MESSAGES[reason]);
      },
    );
  });
});
