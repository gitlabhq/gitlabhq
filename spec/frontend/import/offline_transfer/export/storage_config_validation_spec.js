import {
  validateAndCheckLength,
  isStorageConfigValid,
} from '~/import/offline_transfer/export/storage_config_validation';

const EMPTY_MESSAGE = 'This field is required.';
const tooLong = (max) => `Enter ${max} characters or fewer.`;
const MAX_REGION_LENGTH = 50;

const validConfig = {
  accessKeyId: 'myAccessKey',
  secretAccessKey: 'mySecretKey',
  region: 'us-east-1',
  bucketName: 'my-export-bucket',
};

describe('OfflineTransfer storage_config_validation.js', () => {
  describe('validateAndCheckLength', () => {
    const MAX = 5;

    it.each([
      ['an empty string', ''],
      ['whitespace-only string', '   '],
      ['null', null],
      ['undefined', undefined],
    ])('returns the empty message for %s', (_, value) => {
      expect(validateAndCheckLength(value, EMPTY_MESSAGE, MAX)).toBe(EMPTY_MESSAGE);
    });

    it.each([
      ['a single character', 'a'],
      ['a value shorter than the max', 'abcd'],
      ['a value exactly at the max', 'abcde'],
    ])('returns null for %s', (_, value) => {
      expect(validateAndCheckLength(value, EMPTY_MESSAGE, MAX)).toBeNull();
    });

    it('returns the too-long message for a value over the max length', () => {
      expect(validateAndCheckLength('abcdef', EMPTY_MESSAGE, MAX)).toBe(tooLong(MAX));
    });

    it('compares the trimmed length toward the max length', () => {
      expect(validateAndCheckLength('  abc  ', EMPTY_MESSAGE, MAX)).toBeNull();
    });

    it('does not reject internal whitespace or special characters', () => {
      expect(validateAndCheckLength('a b!', EMPTY_MESSAGE, MAX)).toBeNull();
    });
  });

  describe('isStorageConfigValid', () => {
    it('returns true when every field passes validation', () => {
      expect(isStorageConfigValid(validConfig)).toBe(true);
    });

    it.each([
      ['a required field is empty', { ...validConfig, bucketName: '' }],
      ['a required field is missing', { ...validConfig, accessKeyId: undefined }],
      [
        'a field exceeds its max length',
        { ...validConfig, region: 'a'.repeat(MAX_REGION_LENGTH + 1) },
      ],
    ])('returns false when %s', (_, config) => {
      expect(isStorageConfigValid(config)).toBe(false);
    });
  });
});
