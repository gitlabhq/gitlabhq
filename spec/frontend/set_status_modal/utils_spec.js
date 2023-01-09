import { isUserBusy, computedClearStatusAfterValue } from '~/set_status_modal/utils';
import { AVAILABILITY_STATUS, NEVER_TIME_RANGE } from '~/set_status_modal/constants';
import { timeRanges } from '~/vue_shared/constants';

const [thirtyMinutes] = timeRanges;

describe('Set status modal utils', () => {
  describe('isUserBusy', () => {
    it.each`
      value                          | result
      ${''}                          | ${false}
      ${'fake status'}               | ${false}
      ${AVAILABILITY_STATUS.NOT_SET} | ${false}
      ${AVAILABILITY_STATUS.BUSY}    | ${true}
    `('with $value returns $result', ({ value, result }) => {
      expect(isUserBusy(value)).toBe(result);
    });
  });

  describe('computedClearStatusAfterValue', () => {
    it.each`
      value               | expected
      ${null}             | ${null}
      ${NEVER_TIME_RANGE} | ${null}
      ${thirtyMinutes}    | ${thirtyMinutes.shortcut}
    `('with $value returns $expected', ({ value, expected }) => {
      expect(computedClearStatusAfterValue(value)).toBe(expected);
    });
  });
});
