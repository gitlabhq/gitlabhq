import { isUserBusy } from '~/set_status_modal/utils';
import { AVAILABILITY_STATUS } from '~/set_status_modal/constants';

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
});
