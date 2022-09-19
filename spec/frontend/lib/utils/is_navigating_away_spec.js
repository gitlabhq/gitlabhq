import { isNavigatingAway, setNavigatingForTestsOnly } from '~/lib/utils/is_navigating_away';

describe('isNavigatingAway', () => {
  beforeEach(() => {
    // Make sure each test starts with the same state
    setNavigatingForTestsOnly(false);
  });

  it.each([false, true])('returns the navigation flag with value %s', (flag) => {
    setNavigatingForTestsOnly(flag);
    expect(isNavigatingAway()).toEqual(flag);
  });

  describe('when the browser starts navigating away', () => {
    it('returns true', () => {
      expect(isNavigatingAway()).toEqual(false);

      window.dispatchEvent(new Event('beforeunload'));

      expect(isNavigatingAway()).toEqual(true);
    });
  });
});
