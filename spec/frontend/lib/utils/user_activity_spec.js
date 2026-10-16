import {
  IDLE_THRESHOLD_MS,
  isUserIdle,
  setLastActivityAtForTestsOnly,
} from '~/lib/utils/user_activity';

describe('~/lib/utils/user_activity', () => {
  const now = 1_000_000_000;

  beforeEach(() => {
    jest.spyOn(performance, 'now').mockReturnValue(now);
  });

  describe('isUserIdle', () => {
    it('returns false while the last activity is within the threshold', () => {
      setLastActivityAtForTestsOnly(now - IDLE_THRESHOLD_MS + 1);

      expect(isUserIdle()).toBe(false);
    });

    it('returns true once the threshold has passed since the last activity', () => {
      setLastActivityAtForTestsOnly(now - IDLE_THRESHOLD_MS);

      expect(isUserIdle()).toBe(true);
    });
  });

  describe.each(['pointerdown', 'pointermove', 'keydown', 'wheel', 'scroll'])(
    'when a %s event fires',
    (eventType) => {
      beforeEach(() => {
        setLastActivityAtForTestsOnly(0);
      });

      it('records activity from the window', () => {
        window.dispatchEvent(new Event(eventType));

        expect(isUserIdle()).toBe(false);
      });

      it('records activity from an element, even if the event does not bubble', () => {
        document.body.dispatchEvent(new Event(eventType, { bubbles: false }));

        expect(isUserIdle()).toBe(false);
      });
    },
  );
});
