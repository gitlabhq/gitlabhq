import { generateSecureRandom, generateNonce } from '~/observability/utils/nonce';

jest.mock('~/locale', () => ({
  s__: jest.fn((key) => {
    const translations = {
      'Observability|Length must be a positive integer': 'Length must be a positive integer',
      'Observability|Crypto API not available': 'Crypto API not available',
    };
    return translations[key] || key;
  }),
}));

describe('nonce utilities', () => {
  beforeEach(() => {
    Object.defineProperty(window, 'crypto', {
      value: {
        getRandomValues: jest.fn((arr) => {
          const result = new Uint8Array(arr.length);
          for (let i = 0; i < arr.length; i += 1) {
            result[i] = i % 256;
          }
          arr.set(result);
          return arr;
        }),
      },
      writable: true,
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('generateSecureRandom', () => {
    it('generates a hex string with default length of 32 bytes (64 hex characters)', () => {
      const result = generateSecureRandom();

      expect(result).toHaveLength(64);
      expect(result).toMatch(/^[0-9a-f]+$/);
      expect(window.crypto.getRandomValues).toHaveBeenCalledWith(expect.any(Uint8Array));
      expect(window.crypto.getRandomValues).toHaveBeenCalledTimes(1);
    });

    it('generates a hex string with custom length', () => {
      const customLength = 16;
      const result = generateSecureRandom(customLength);

      expect(result).toHaveLength(32);
      expect(result).toMatch(/^[0-9a-f]+$/);
      expect(window.crypto.getRandomValues).toHaveBeenCalledWith(expect.any(Uint8Array));

      const calledArray = window.crypto.getRandomValues.mock.calls[0][0];
      expect(calledArray).toHaveLength(customLength);
    });

    it('generates different results on consecutive calls', () => {
      let callCount = 0;
      window.crypto.getRandomValues.mockImplementation((arr) => {
        const result = new Uint8Array(arr.length);
        for (let i = 0; i < arr.length; i += 1) {
          result[i] = (i + callCount * 10) % 256;
        }
        callCount += 1;
        arr.set(result);
        return arr;
      });

      const result1 = generateSecureRandom(8);
      const result2 = generateSecureRandom(8);

      expect(result1).not.toEqual(result2);
      expect(window.crypto.getRandomValues).toHaveBeenCalledTimes(2);
    });

    describe('input validation', () => {
      it.each([
        { input: 0, description: 'zero' },
        { input: -5, description: 'negative' },
        { input: 3.14, description: 'decimal' },
        { input: '32', description: 'string' },
        { input: null, description: 'null' },
        { input: {}, description: 'object' },
      ])('throws an error when length is $description', ({ input }) => {
        expect(() => generateSecureRandom(input)).toThrow('Length must be a positive integer');
        expect(window.crypto.getRandomValues).not.toHaveBeenCalled();
      });

      it.each([
        { input: 1, description: 'positive integer 1' },
        { input: 100, description: 'positive integer 100' },
      ])('accepts $description', ({ input }) => {
        expect(() => generateSecureRandom(input)).not.toThrow();
        expect(window.crypto.getRandomValues).toHaveBeenCalled();
      });
    });

    describe('crypto API availability', () => {
      it('throws an error when window.crypto is not available', () => {
        delete window.crypto;

        expect(() => generateSecureRandom()).toThrow('Crypto API not available');
      });

      it('throws an error when window.crypto.getRandomValues is not available', () => {
        window.crypto = {};

        expect(() => generateSecureRandom()).toThrow('Crypto API not available');
      });

      it('throws an error when window.crypto.getRandomValues is not a function', () => {
        window.crypto = { getRandomValues: 'not a function' };

        expect(() => generateSecureRandom()).toThrow('Crypto API not available');
      });
    });
  });

  describe('generateNonce', () => {
    it('returns a 32-character hex string (16 bytes)', () => {
      const result = generateNonce();

      expect(result).toHaveLength(32);
      expect(result).toMatch(/^[0-9a-f]+$/);
      expect(window.crypto.getRandomValues).toHaveBeenCalledWith(expect.any(Uint8Array));

      const calledArray = window.crypto.getRandomValues.mock.calls[0][0];
      expect(calledArray).toHaveLength(16);
    });
  });
});
