import { MessageValidator, createMessageValidator } from '~/observability/utils/message_validator';
import { MESSAGE_TYPES, TIMEOUTS } from '~/observability/constants';

jest.mock('~/locale', () => ({
  s__: jest.fn(() => 'Message validation failed'),
}));

describe('MessageValidator', () => {
  let validator;
  const mockNow = 1000000;
  const config = {
    allowedOrigin: 'https://trusted-origin.com',
    allowedMessageType: MESSAGE_TYPES.AUTH_STATUS,
    maxMessageAge: TIMEOUTS.MAX_MESSAGE_AGE,
  };

  const createEvent = (overrides = {}) => ({
    origin: config.allowedOrigin,
    data: {
      type: config.allowedMessageType,
      timestamp: mockNow - 1000,
      nonce: 'valid-nonce',
      counter: 1,
      ...overrides,
    },
  });

  beforeEach(() => {
    validator = new MessageValidator(config.allowedOrigin, config.allowedMessageType, {
      maxMessageAge: config.maxMessageAge,
    });
    jest.spyOn(Date, 'now').mockReturnValue(mockNow);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('constructor', () => {
    it('initializes with provided configuration', () => {
      expect(validator.allowedOrigin).toBe(config.allowedOrigin);
      expect(validator.allowedMessageType).toBe(config.allowedMessageType);
      expect(validator.maxMessageAge).toBe(config.maxMessageAge);
      expect(validator.lastMessageTimestamp).toBe(0);
      expect(validator.timestampTolerance).toBe(5000);
    });

    it('applies sensible defaults when options are omitted', () => {
      const defaultValidator = new MessageValidator(
        config.allowedOrigin,
        config.allowedMessageType,
      );
      expect(defaultValidator.maxMessageAge).toBe(TIMEOUTS.MAX_MESSAGE_AGE);
    });

    it('accepts custom configuration options', () => {
      const customValidator = new MessageValidator(
        config.allowedOrigin,
        config.allowedMessageType,
        {
          timestampTolerance: 10000,
        },
      );
      expect(customValidator.timestampTolerance).toBe(10000);
    });
  });

  describe('validateMessage', () => {
    it('accepts completely valid messages', () => {
      const event = createEvent();
      const result = validator.validateMessage(event, 'valid-nonce', 1);
      expect(result).toEqual({ valid: true });
    });

    describe('rejects invalid messages', () => {
      const invalidCases = [
        {
          name: 'wrong origin',
          event: () => createEvent(),
          modifier: (event) => ({ ...event, origin: 'https://malicious-origin.com' }),
        },
        {
          name: 'malformed data structure',
          event: () => ({ origin: config.allowedOrigin, data: null }),
          modifier: () => {},
        },
        {
          name: 'incorrect message type',
          event: () => createEvent({ type: 'INVALID_TYPE' }),
          modifier: () => {},
        },
        {
          name: 'nonce mismatch',
          event: () => createEvent(),
          modifier: () => {},
          nonce: 'wrong-nonce',
        },
        {
          name: 'counter mismatch',
          event: () => createEvent(),
          modifier: () => {},
          counter: 2,
        },
        {
          name: 'stale timestamp',
          event: () => createEvent({ timestamp: 1 }),
          modifier: () => {},
        },
      ];

      invalidCases.forEach(({ name, event, modifier, nonce = 'valid-nonce', counter = 1 }) => {
        it(`when ${name}`, () => {
          const testEvent = event();
          const modifiedEvent = modifier(testEvent) || testEvent;
          const result = validator.validateMessage(modifiedEvent, nonce, counter);
          expect(result).toEqual({ valid: false, error: 'Message validation failed' });
        });
      });
    });
  });

  describe('origin validation', () => {
    const testCases = [
      { input: config.allowedOrigin, expected: true, description: 'matching origin' },
      { input: 'https://malicious-origin.com', expected: false, description: 'different origin' },
      { input: null, expected: false, description: 'null origin' },
      { input: undefined, expected: false, description: 'undefined origin' },
    ];

    testCases.forEach(({ input, expected, description }) => {
      it(`${expected ? 'accepts' : 'rejects'} ${description}`, () => {
        expect(validator.validateOrigin(input)).toBe(expected);
      });
    });
  });

  describe('data structure validation', () => {
    const validStructure = {
      type: 'string-type',
      timestamp: 123456789,
      nonce: 'string-nonce',
      counter: 42,
    };

    it('accepts well-formed data objects', () => {
      expect(validator.validateStructure(validStructure)).toBe(true);
    });

    describe('rejects malformed data', () => {
      const invalidCases = [
        { input: null, reason: 'null data' },
        { input: undefined, reason: 'undefined data' },
        { input: 'string', reason: 'string instead of object' },
        { input: 123, reason: 'number instead of object' },
        { input: [], reason: 'array instead of object' },
        { input: { ...validStructure, type: 123 }, reason: 'non-string type' },
        { input: { ...validStructure, timestamp: '123456789' }, reason: 'non-numeric timestamp' },
        { input: { ...validStructure, nonce: 123 }, reason: 'non-string nonce' },
        { input: { ...validStructure, counter: '42' }, reason: 'non-numeric counter' },
      ];

      invalidCases.forEach(({ input, reason }) => {
        it(`when data has ${reason}`, () => {
          expect(validator.validateStructure(input)).toBe(false);
        });
      });

      it('when required fields are missing', () => {
        const requiredFields = ['type', 'timestamp', 'nonce', 'counter'];
        requiredFields.forEach((field) => {
          const incompleteData = { ...validStructure };
          delete incompleteData[field];
          expect(validator.validateStructure(incompleteData)).toBe(false);
        });
      });
    });
  });

  describe('message type validation', () => {
    const testCases = [
      { input: config.allowedMessageType, expected: true },
      { input: 'WRONG_TYPE', expected: false },
      { input: null, expected: false },
      { input: undefined, expected: false },
    ];

    testCases.forEach(({ input, expected }) => {
      it(`${expected ? 'accepts' : 'rejects'} ${input || 'falsy values'}`, () => {
        expect(validator.validateType(input)).toBe(expected);
      });
    });
  });

  describe('nonce validation', () => {
    it('accepts matching nonces', () => {
      expect(validator.validateNonce('test-nonce', 'test-nonce')).toBe(true);
    });

    const invalidCases = [
      { actual: 'nonce1', expected: 'nonce2', reason: 'mismatched nonces' },
      { actual: null, expected: 'test', reason: 'null actual nonce' },
      { actual: 'test', expected: null, reason: 'null expected nonce' },
      { actual: undefined, expected: 'test', reason: 'undefined actual nonce' },
      { actual: 'test', expected: undefined, reason: 'undefined expected nonce' },
    ];

    invalidCases.forEach(({ actual, expected, reason }) => {
      it(`rejects ${reason}`, () => {
        expect(validator.validateNonce(actual, expected)).toBe(false);
      });
    });
  });

  describe('counter validation', () => {
    it('accepts matching counters', () => {
      expect(validator.validateCounter(42, 42)).toBe(true);
    });

    const invalidCases = [
      { actual: 1, expected: 2, reason: 'mismatched counters' },
      { actual: null, expected: 1, reason: 'null actual counter' },
      { actual: 1, expected: null, reason: 'null expected counter' },
      { actual: undefined, expected: 1, reason: 'undefined actual counter' },
      { actual: 1, expected: undefined, reason: 'undefined expected counter' },
    ];

    invalidCases.forEach(({ actual, expected, reason }) => {
      it(`rejects ${reason}`, () => {
        expect(validator.validateCounter(actual, expected)).toBe(false);
      });
    });
  });

  describe('timestamp validation', () => {
    beforeEach(() => {
      validator.reset();
    });

    describe('message age validation', () => {
      it('accepts recent timestamps', () => {
        const recentTimestamp = mockNow - 1000;
        expect(validator.validateTimestamp(recentTimestamp)).toBe(true);
        expect(validator.lastMessageTimestamp).toBe(recentTimestamp);
      });

      it('rejects timestamps older than maximum age', () => {
        const staleTimestamp = mockNow - config.maxMessageAge - 1000;
        expect(validator.validateTimestamp(staleTimestamp)).toBe(false);
      });

      it('accepts timestamps at the exact age boundary', () => {
        const boundaryTimestamp = mockNow - config.maxMessageAge;
        expect(validator.validateTimestamp(boundaryTimestamp)).toBe(true);
      });

      it('rejects future timestamps beyond clock skew tolerance', () => {
        const futureTimestamp = mockNow + config.maxMessageAge + 1000;
        expect(validator.validateTimestamp(futureTimestamp)).toBe(false);
      });
    });

    describe('duplicate timestamp detection', () => {
      it('rejects exact duplicate timestamps', () => {
        const timestamp = mockNow - 1000;
        expect(validator.validateTimestamp(timestamp)).toBe(true);
        expect(validator.validateTimestamp(timestamp)).toBe(false);
      });
    });

    describe('out-of-order message handling', () => {
      const baseTimestamp = mockNow - 1000;
      const tolerance = 5000;

      beforeEach(() => {
        validator.validateTimestamp(baseTimestamp);
      });

      it('allows messages within tolerance window', () => {
        const withinTolerance = [
          baseTimestamp - 2000,
          baseTimestamp - 4000,
          baseTimestamp + 2000,
          baseTimestamp + 4000,
        ];

        withinTolerance.forEach((timestamp) => {
          expect(validator.validateTimestamp(timestamp)).toBe(true);
        });
      });

      it('rejects messages outside tolerance window', () => {
        const outsideTolerance = [
          baseTimestamp - (tolerance + 1000),
          baseTimestamp - (tolerance + 2000),
        ];

        outsideTolerance.forEach((timestamp) => {
          expect(validator.validateTimestamp(timestamp)).toBe(false);
        });
      });

      it('updates last timestamp when receiving newer messages within tolerance', () => {
        const newerTimestamp = baseTimestamp + 3000;
        expect(validator.validateTimestamp(newerTimestamp)).toBe(true);
        expect(validator.lastMessageTimestamp).toBe(newerTimestamp);
      });

      it('preserves last timestamp when receiving older messages within tolerance', () => {
        const olderTimestamp = baseTimestamp - 3000;
        expect(validator.validateTimestamp(olderTimestamp)).toBe(true);
        expect(validator.lastMessageTimestamp).toBe(baseTimestamp);
      });
    });

    it('handles progressive timestamp advancement correctly', () => {
      const timestamps = [995000, 1005000, 1015000];
      timestamps.forEach((timestamp) => {
        expect(validator.validateTimestamp(timestamp)).toBe(true);
      });
    });

    it('manages cleanup of old timestamps from tracking set', () => {
      const recentTimestamp = mockNow - 1000;
      validator.validateTimestamp(recentTimestamp);
      expect(validator.recentTimestamps.has(recentTimestamp)).toBe(true);

      validator.cleanupOldTimestamps(mockNow + config.maxMessageAge + 2000);
      expect(validator.recentTimestamps.has(recentTimestamp)).toBe(false);
    });
  });

  describe('validator state management', () => {
    it('properly resets all state when reset() is called', () => {
      validator.validateTimestamp(mockNow - 1000);
      validator.trackNonce('test-nonce');

      expect(validator.lastMessageTimestamp).not.toBe(0);
      expect(validator.recentTimestamps.size).toBeGreaterThan(0);

      validator.reset();
      expect(validator.lastMessageTimestamp).toBe(0);
      expect(validator.recentTimestamps.size).toBe(0);
    });

    it('allows reprocessing previously seen timestamps after reset', () => {
      const timestamp = mockNow - 1000;

      expect(validator.validateTimestamp(timestamp)).toBe(true);
      expect(validator.validateTimestamp(timestamp)).toBe(false);

      validator.reset();
      expect(validator.validateTimestamp(timestamp)).toBe(true);
    });

    it('provides comprehensive validation statistics', () => {
      validator.validateTimestamp(mockNow - 1000);
      validator.trackNonce('test-nonce');

      const stats = validator.getValidationStats();
      expect(stats).toEqual({
        lastMessageTimestamp: mockNow - 1000,
        processedNoncesCount: 1,
        recentTimestampsCount: 1,
        allowedOrigin: config.allowedOrigin,
        allowedMessageType: config.allowedMessageType,
        timestampTolerance: 5000,
      });
    });
  });

  describe('trackNonce functionality', () => {
    beforeEach(() => {
      validator = new MessageValidator(config.allowedOrigin, config.allowedMessageType, {
        maxMessageAge: config.maxMessageAge,
        maxNonceHistory: 5,
      });
    });

    it('tracks nonces and maintains history within limit', () => {
      const nonces = ['nonce-1', 'nonce-2', 'nonce-3', 'nonce-4', 'nonce-5'];

      nonces.forEach((nonce) => {
        validator.trackNonce(nonce);
      });

      expect(validator.processedNonces.size).toBe(5);
      nonces.forEach((nonce) => {
        expect(validator.processedNonces.has(nonce)).toBe(true);
      });
    });

    it('removes oldest nonces when exceeding maxNonceHistory', () => {
      const nonces = ['nonce-1', 'nonce-2', 'nonce-3', 'nonce-4', 'nonce-5', 'nonce-6', 'nonce-7'];

      nonces.forEach((nonce) => {
        validator.trackNonce(nonce);
      });

      expect(validator.processedNonces.size).toBe(5);

      expect(validator.processedNonces.has('nonce-1')).toBe(false);
      expect(validator.processedNonces.has('nonce-2')).toBe(false);

      expect(validator.processedNonces.has('nonce-3')).toBe(true);
      expect(validator.processedNonces.has('nonce-4')).toBe(true);
      expect(validator.processedNonces.has('nonce-5')).toBe(true);
      expect(validator.processedNonces.has('nonce-6')).toBe(true);
      expect(validator.processedNonces.has('nonce-7')).toBe(true);
    });

    it('maintains exact maxNonceHistory size when adding many nonces', () => {
      const manyNonces = Array.from({ length: 20 }, (_, i) => `nonce-${i + 1}`);

      manyNonces.forEach((nonce) => {
        validator.trackNonce(nonce);
      });

      expect(validator.processedNonces.size).toBe(5); // maxNonceHistory

      const expectedNonces = ['nonce-16', 'nonce-17', 'nonce-18', 'nonce-19', 'nonce-20'];
      expectedNonces.forEach((nonce) => {
        expect(validator.processedNonces.has(nonce)).toBe(true);
      });
    });

    it('stores timestamps with nonces', () => {
      const testNonce = 'test-nonce';
      const beforeTime = Date.now();

      validator.trackNonce(testNonce);

      const afterTime = Date.now();
      const storedTime = validator.processedNonces.get(testNonce);

      expect(storedTime).toBeGreaterThanOrEqual(beforeTime);
      expect(storedTime).toBeLessThanOrEqual(afterTime);
    });

    it('handles duplicate nonce tracking gracefully', () => {
      const nonce = 'duplicate-nonce';

      validator.trackNonce(nonce);
      const firstTime = validator.processedNonces.get(nonce);

      jest.spyOn(Date, 'now').mockReturnValue(mockNow + 100);

      validator.trackNonce(nonce);
      const secondTime = validator.processedNonces.get(nonce);

      expect(secondTime).toBeGreaterThan(firstTime);
      expect(validator.processedNonces.size).toBe(1);
    });

    it('works with default maxNonceHistory when not specified', () => {
      const defaultValidator = new MessageValidator(
        config.allowedOrigin,
        config.allowedMessageType,
        { maxMessageAge: config.maxMessageAge },
      );

      const manyNonces = Array.from({ length: 1005 }, (_, i) => `nonce-${i + 1}`);

      manyNonces.forEach((nonce) => {
        defaultValidator.trackNonce(nonce);
      });

      expect(defaultValidator.processedNonces.size).toBe(1000); // Default maxNonceHistory
    });
  });

  describe('factory function', () => {
    it('creates properly configured MessageValidator instances', () => {
      const createdValidator = createMessageValidator('https://example.com');

      expect(createdValidator).toBeInstanceOf(MessageValidator);
      expect(createdValidator.allowedOrigin).toBe('https://example.com');
      expect(createdValidator.allowedMessageType).toBe(MESSAGE_TYPES.AUTH_STATUS);
      expect(createdValidator.maxMessageAge).toBe(TIMEOUTS.MAX_MESSAGE_AGE);
    });
  });

  describe('integration scenarios', () => {
    it('processes sequential valid messages correctly', () => {
      const messages = [
        { timestamp: 995000, nonce: 'nonce-1', counter: 1 },
        { timestamp: 996000, nonce: 'nonce-2', counter: 2 },
        { timestamp: 997000, nonce: 'nonce-3', counter: 3 },
      ];

      messages.forEach(({ timestamp, nonce, counter }) => {
        const event = createEvent({ timestamp, nonce, counter });
        expect(validator.validateMessage(event, nonce, counter)).toEqual({ valid: true });
      });

      expect(validator.lastMessageTimestamp).toBe(997000);
    });

    it('maintains state consistency during mixed valid/invalid message processing', () => {
      const validEvent = createEvent({ timestamp: 995000, nonce: 'valid-nonce', counter: 1 });
      const invalidEvent = createEvent({
        timestamp: 996000,
        nonce: 'invalid-nonce',
        counter: 2,
      });

      expect(validator.validateMessage(validEvent, 'valid-nonce', 1)).toEqual({ valid: true });
      expect(validator.validateMessage(invalidEvent, 'expected-nonce', 2)).toEqual({
        valid: false,
        error: 'Message validation failed',
      });

      const nextValidEvent = createEvent({ timestamp: 997000, nonce: 'next-nonce', counter: 3 });
      expect(validator.validateMessage(nextValidEvent, 'next-nonce', 3)).toEqual({ valid: true });
    });

    it('handles attempt to replay previously processed messages', () => {
      const event = createEvent({ timestamp: 995000, nonce: 'replay-nonce', counter: 1 });

      expect(validator.validateMessage(event, 'replay-nonce', 1)).toEqual({ valid: true });
      expect(validator.validateMessage(event, 'replay-nonce', 1)).toEqual({
        valid: false,
        error: 'Message validation failed',
      });
    });
  });
});
