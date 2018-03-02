import axios from './lib/utils/axios_utils';

const SAMPLE_PERCENT = 100;
const SEND_DELAY_SECONDS = 5;

function select() {
  if (!window.performance || !window.performance.timing) return false;
  return Math.random() * 100 < SAMPLE_PERCENT;
}

function sendClientTimingStats() {
  const timing = window.performance.timing;
  const body = {
    connect: timing.connectEnd - timing.connectStart,
    domainLookup: timing.domainLookupEnd - timing.domainLookupStart,
    request: timing.responseEnd - timing.requestStart,
    requestTtfb: timing.responseStart - timing.requestStart,
    interactive: timing.domInteractive - timing.domLoading,
    contentComplete: timing.domContentLoadedEventEnd - timing.domLoading,
    loaded: timing.loadEventEnd - timing.domLoading,
  };

  axios.post('/api/v4/timing/stats', body);
}

function ensureClientTiming() {
  if (!select()) return;

  window.addEventListener('load', () => {
    setTimeout(sendClientTimingStats, SEND_DELAY_SECONDS);
  }, false);
}

export { ensureClientTiming as default, sendClientTimingStats };
