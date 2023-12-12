import {
  getAge,
  calculateDeploymentStatus,
  calculateStatefulSetStatus,
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
});
