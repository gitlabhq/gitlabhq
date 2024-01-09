import {
  getAge,
  calculateDeploymentStatus,
  calculateStatefulSetStatus,
  calculateDaemonSetStatus,
  calculateJobStatus,
  calculateCronJobStatus,
  generateServicePortsString,
} from '~/kubernetes_dashboard/helpers/k8s_integration_helper';
import { useFakeDate } from 'helpers/fake_date';

describe('k8s_integration_helper', () => {
  describe('getAge', () => {
    useFakeDate(2023, 10, 23, 10, 10);

    it.each`
      condition                          | measures     | timestamp                 | expected
      ${'timestamp > 1 day'}             | ${'days'}    | ${'2023-07-31T11:50:59Z'} | ${'114d'}
      ${'timestamp = 1 day'}             | ${'days'}    | ${'2023-11-21T11:50:59Z'} | ${'1d'}
      ${'1 day > timestamp > 1 hour'}    | ${'hours'}   | ${'2023-11-22T11:50:59Z'} | ${'22h'}
      ${'timestamp = 1 hour'}            | ${'hours'}   | ${'2023-11-23T08:50:59Z'} | ${'1h'}
      ${'1 hour > timestamp >1  minute'} | ${'minutes'} | ${'2023-11-23T09:50:59Z'} | ${'19m'}
      ${'timestamp = 1 minute'}          | ${'minutes'} | ${'2023-11-23T10:08:59Z'} | ${'1m'}
      ${'1 minute > timestamp'}          | ${'seconds'} | ${'2023-11-23T10:09:17Z'} | ${'43s'}
      ${'timestamp = 1 second'}          | ${'seconds'} | ${'2023-11-23T10:09:59Z'} | ${'1s'}
    `('returns age in $measures when $condition', ({ timestamp, expected }) => {
      expect(getAge(timestamp)).toBe(expected);
    });
  });

  describe('calculateDeploymentStatus', () => {
    const pending = {
      conditions: [
        { type: 'Available', status: 'False' },
        { type: 'Progressing', status: 'True' },
      ],
    };
    const ready = {
      conditions: [
        { type: 'Available', status: 'True' },
        { type: 'Progressing', status: 'False' },
      ],
    };
    const failed = {
      conditions: [
        { type: 'Available', status: 'False' },
        { type: 'Progressing', status: 'False' },
      ],
    };

    it.each`
      condition                                        | status     | expected
      ${'Available is false and Progressing is true'}  | ${pending} | ${'Pending'}
      ${'Available is true and Progressing is false'}  | ${ready}   | ${'Ready'}
      ${'Available is false and Progressing is false'} | ${failed}  | ${'Failed'}
    `('returns status as $expected when $condition', ({ status, expected }) => {
      expect(calculateDeploymentStatus({ status })).toBe(expected);
    });
  });

  describe('calculateStatefulSetStatus', () => {
    const ready = {
      status: { readyReplicas: 2 },
      spec: { replicas: 2 },
    };
    const failed = {
      status: { readyReplicas: 1 },
      spec: { replicas: 2 },
    };

    it.each`
      condition                                                  | item      | expected
      ${'there are less readyReplicas than replicas in spec'}    | ${failed} | ${'Failed'}
      ${'there are the same amount of readyReplicas as in spec'} | ${ready}  | ${'Ready'}
    `('returns status as $expected when $condition', ({ item, expected }) => {
      expect(calculateStatefulSetStatus(item)).toBe(expected);
    });
  });

  describe('calculateDaemonSetStatus', () => {
    const ready = {
      status: { numberMisscheduled: 0, numberReady: 2, desiredNumberScheduled: 2 },
    };
    const failed = {
      status: { numberMisscheduled: 1, numberReady: 1, desiredNumberScheduled: 2 },
    };

    it.each`
      condition                                                                                        | item      | expected
      ${'there are less numberReady than desiredNumberScheduled or the numberMisscheduled is present'} | ${failed} | ${'Failed'}
      ${'there are the same amount of numberReady and desiredNumberScheduled'}                         | ${ready}  | ${'Ready'}
    `('returns status as $expected when $condition', ({ item, expected }) => {
      expect(calculateDaemonSetStatus(item)).toBe(expected);
    });
  });

  describe('calculateJobStatus', () => {
    const completed = {
      status: { failed: 0, succeeded: 2 },
      spec: { completions: 2 },
    };
    const failed = {
      status: { failed: 1, succeeded: 1 },
      spec: { completions: 2 },
    };
    const anotherFailed = {
      status: { failed: 0, succeeded: 1 },
      spec: { completions: 2 },
    };

    it.each`
      condition                                                                          | item             | expected
      ${'there are no failed and succeeded amount is equal to completions number'}       | ${completed}     | ${'Completed'}
      ${'there are some failed statuses'}                                                | ${failed}        | ${'Failed'}
      ${'there are some failed and succeeded amount is not equal to completions number'} | ${anotherFailed} | ${'Failed'}
    `('returns status as $expected when $condition', ({ item, expected }) => {
      expect(calculateJobStatus(item)).toBe(expected);
    });
  });

  describe('calculateCronJobStatus', () => {
    const ready = {
      status: { active: 0, lastScheduleTime: '2023-11-21T11:50:59Z' },
      spec: { suspend: 0 },
    };
    const failed = {
      status: { active: 1, lastScheduleTime: null },
      spec: { suspend: 0 },
    };
    const suspended = {
      status: { active: 0, lastScheduleTime: '2023-11-21T11:50:59Z' },
      spec: { suspend: 1 },
    };

    it.each`
      condition                                                          | item         | expected
      ${'there are no active and the lastScheduleTime is present'}       | ${ready}     | ${'Ready'}
      ${'there are some active and the lastScheduleTime is not present'} | ${failed}    | ${'Failed'}
      ${'there are some suspend in the spec'}                            | ${suspended} | ${'Suspended'}
    `('returns status as $expected when $condition', ({ item, expected }) => {
      expect(calculateCronJobStatus(item)).toBe(expected);
    });
  });

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
});
