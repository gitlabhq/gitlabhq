import { getAge } from '~/kubernetes_dashboard/helpers/k8s_integration_helper';
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
});
