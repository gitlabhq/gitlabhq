import { formatTimeSpent } from '~/lib/utils/datetime/time_spent_utility';

describe('Time spent utils', () => {
  describe('formatTimeSpent', () => {
    describe('with limitToHours false', () => {
      it('formats 34500 seconds to `1d 1h 35m`', () => {
        expect(formatTimeSpent(34500)).toEqual('1d 1h 35m');
      });

      it('formats -34500 seconds to `- 1d 1h 35m`', () => {
        expect(formatTimeSpent(-34500)).toEqual('- 1d 1h 35m');
      });
    });

    describe('with limitToHours true', () => {
      it('formats 34500 seconds to `9h 35m`', () => {
        expect(formatTimeSpent(34500, true)).toEqual('9h 35m');
      });

      it('formats -34500 seconds to `- 9h 35m`', () => {
        expect(formatTimeSpent(-34500, true)).toEqual('- 9h 35m');
      });
    });
  });
});
