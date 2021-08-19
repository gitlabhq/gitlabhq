import api from '~/api';
import { DEFER_DURATION } from '~/diffs/constants';
import { queueRedisHllEvents } from '~/diffs/utils/queue_events';

jest.mock('~/api', () => ({
  trackRedisHllUserEvent: jest.fn(),
}));

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
  });
});
