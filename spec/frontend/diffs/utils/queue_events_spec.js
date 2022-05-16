import api from '~/api';
import { DEFER_DURATION, TRACKING_CAP_KEY, TRACKING_CAP_LENGTH } from '~/diffs/constants';
import { queueRedisHllEvents } from '~/diffs/utils/queue_events';

jest.mock('~/api', () => ({
  trackRedisHllUserEvent: jest.fn(),
}));

beforeAll(() => {
  localStorage.clear();
});

describe('diffs events queue', () => {
  describe('queueRedisHllEvents', () => {
    it('does not dispatch the event immediately', () => {
      queueRedisHllEvents(['know_event']);
      expect(api.trackRedisHllUserEvent).not.toHaveBeenCalled();
    });

    it('does dispatch the event after the defer duration', () => {
      queueRedisHllEvents(['know_event']);
      jest.advanceTimersByTime(DEFER_DURATION + 1);
      expect(api.trackRedisHllUserEvent).toHaveBeenCalled();
      expect(localStorage.getItem(TRACKING_CAP_KEY)).toBe(null);
    });

    it('increase defer duration based on the provided events count', () => {
      let deferDuration = DEFER_DURATION + 1;
      const events = ['know_event_a', 'know_event_b', 'know_event_c'];
      queueRedisHllEvents(events);

      expect(api.trackRedisHllUserEvent).not.toHaveBeenCalled();

      events.forEach((event, index) => {
        jest.advanceTimersByTime(deferDuration);
        expect(api.trackRedisHllUserEvent).toHaveBeenLastCalledWith(event);
        deferDuration *= index + 1;
      });
    });

    describe('with tracking cap verification', () => {
      const currentTimestamp = Date.now();

      beforeEach(() => {
        localStorage.clear();
      });

      it('dispatches the event if cap value is not found', () => {
        queueRedisHllEvents(['know_event'], { verifyCap: true });
        jest.advanceTimersByTime(DEFER_DURATION + 1);
        expect(api.trackRedisHllUserEvent).toHaveBeenCalled();
        expect(localStorage.getItem(TRACKING_CAP_KEY)).toBe(currentTimestamp.toString());
      });

      it('dispatches the event if cap value is less than limit', () => {
        localStorage.setItem(TRACKING_CAP_KEY, 1);
        queueRedisHllEvents(['know_event'], { verifyCap: true });
        jest.advanceTimersByTime(DEFER_DURATION + 1);
        expect(api.trackRedisHllUserEvent).toHaveBeenCalled();
        expect(localStorage.getItem(TRACKING_CAP_KEY)).toBe(currentTimestamp.toString());
      });

      it('does not dispatch the event if cap value is greater than limit', () => {
        localStorage.setItem(TRACKING_CAP_KEY, currentTimestamp - (TRACKING_CAP_LENGTH + 1));
        queueRedisHllEvents(['know_event'], { verifyCap: true });
        jest.advanceTimersByTime(DEFER_DURATION + 1);
        expect(api.trackRedisHllUserEvent).toHaveBeenCalled();
      });
    });
  });
});
