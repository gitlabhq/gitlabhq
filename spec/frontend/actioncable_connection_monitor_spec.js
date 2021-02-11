import ConnectionMonitor from '~/actioncable_connection_monitor';

describe('ConnectionMonitor', () => {
  let monitor;

  beforeEach(() => {
    monitor = new ConnectionMonitor({});
  });

  describe('#getPollInterval', () => {
    beforeEach(() => {
      Math.originalRandom = Math.random;
    });
    afterEach(() => {
      Math.random = Math.originalRandom;
    });

    const { staleThreshold, reconnectionBackoffRate } = ConnectionMonitor;
    const backoffFactor = 1 + reconnectionBackoffRate;
    const ms = 1000;

    it('uses exponential backoff', () => {
      Math.random = () => 0;

      monitor.reconnectAttempts = 0;
      expect(monitor.getPollInterval()).toEqual(staleThreshold * ms);

      monitor.reconnectAttempts = 1;
      expect(monitor.getPollInterval()).toEqual(staleThreshold * backoffFactor * ms);

      monitor.reconnectAttempts = 2;
      expect(monitor.getPollInterval()).toEqual(
        staleThreshold * backoffFactor * backoffFactor * ms,
      );
    });

    it('caps exponential backoff after some number of reconnection attempts', () => {
      Math.random = () => 0;
      monitor.reconnectAttempts = 42;
      const cappedPollInterval = monitor.getPollInterval();

      monitor.reconnectAttempts = 9001;
      expect(monitor.getPollInterval()).toEqual(cappedPollInterval);
    });

    it('uses 100% jitter when 0 reconnection attempts', () => {
      Math.random = () => 0;
      expect(monitor.getPollInterval()).toEqual(staleThreshold * ms);

      Math.random = () => 0.5;
      expect(monitor.getPollInterval()).toEqual(staleThreshold * 1.5 * ms);
    });

    it('uses reconnectionBackoffRate for jitter when >0 reconnection attempts', () => {
      monitor.reconnectAttempts = 1;

      Math.random = () => 0.25;
      expect(monitor.getPollInterval()).toEqual(
        staleThreshold * backoffFactor * (1 + reconnectionBackoffRate * 0.25) * ms,
      );

      Math.random = () => 0.5;
      expect(monitor.getPollInterval()).toEqual(
        staleThreshold * backoffFactor * (1 + reconnectionBackoffRate * 0.5) * ms,
      );
    });

    it('applies jitter after capped exponential backoff', () => {
      monitor.reconnectAttempts = 9001;

      Math.random = () => 0;
      const withoutJitter = monitor.getPollInterval();
      Math.random = () => 0.5;
      const withJitter = monitor.getPollInterval();

      expect(withJitter).toBeGreaterThan(withoutJitter);
    });
  });
});
