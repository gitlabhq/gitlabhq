import { delay } from 'lodash';
import api from '~/api';
import { DEFER_DURATION, TRACKING_CAP_KEY, TRACKING_CAP_LENGTH } from '../constants';

function shouldDispatchEvent() {
  const timestamp = parseInt(localStorage.getItem(TRACKING_CAP_KEY), 10);

  if (Number.isNaN(timestamp)) {
    return true;
  }

  return timestamp + TRACKING_CAP_LENGTH < Date.now();
}

export function dispatchRedisHllUserEvent(event, deferDuration = 0) {
  delay(() => api.trackRedisHllUserEvent(event), deferDuration);
}

export function queueRedisHllEvents(events, { verifyCap = false } = {}) {
  if (verifyCap) {
    if (!shouldDispatchEvent()) {
      return;
    }

    localStorage.setItem(TRACKING_CAP_KEY, Date.now());
  }

  events.forEach((event, index) => {
    dispatchRedisHllUserEvent(event, DEFER_DURATION * (index + 1));
  });
}
