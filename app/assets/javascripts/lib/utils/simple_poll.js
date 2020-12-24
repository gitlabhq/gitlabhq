import { differenceInMilliseconds } from '~/lib/utils/datetime_utility';

export default (fn, { interval = 2000, timeout = 60000 } = {}) => {
  const startTime = Date.now();

  return new Promise((resolve, reject) => {
    const stop = (arg) => (arg instanceof Error ? reject(arg) : resolve(arg));
    const next = () => {
      if (timeout === 0 || differenceInMilliseconds(startTime) < timeout) {
        setTimeout(fn.bind(null, next, stop), interval);
      } else {
        reject(new Error('SIMPLE_POLL_TIMEOUT'));
      }
    };
    fn(next, stop);
  });
};
