import { delay } from 'lodash';
import api from '~/api';
import { DEFER_DURATION } from '../constants';

function trackRedisHllUserEvent(event, deferDuration = 0) {
  delay(() => api.trackRedisHllUserEvent(event), deferDuration);
}

export function queueRedisHllEvents(events) {
  events.forEach((event, index) => {
    trackRedisHllUserEvent(event, DEFER_DURATION * (index + 1));
  });
}
