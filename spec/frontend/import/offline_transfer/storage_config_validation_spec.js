import {
  getFieldError,
  isStorageConfigValid,
  isImportStorageConfigValid,
} from '~/import/offline_transfer/storage_config_validation';

const EMPTY_MESSAGE = 'This field is required.';
const tooLong = (max) => `Enter ${max} characters or fewer.`;
const MAX_REGION_LENGTH = 50;
const MAX_EXPORT_PREFIX_LENGTH = 255;

const validConfig = {
  accessKeyId: 'myAccessKey',
  secretAccessKey: 'mySecretKey',
  region: 'us-east-1',
  bucketName: 'my-export-bucket',
};

describe('OfflineTransfer storage_config_validation.js', () => {
  describe('getFieldError', () => {
    const MAX = 5;

    it.each([
      ['an empty string', ''],
      ['whitespace-only string', '   '],
      ['null', null],
      ['undefined', undefined],
    ])('returns the empty message for %s', (_, value) => {
      expect(getFieldError(value, EMPTY_MESSAGE, MAX)).toBe(EMPTY_MESSAGE);
    });

    it.each([
      ['a single character', 'a'],
      ['a value shorter than the max', 'abcd'],
      ['a value exactly at the max', 'abcde'],
    ])('returns null for %s', (_, value) => {
      expect(getFieldError(value, EMPTY_MESSAGE, MAX)).toBeNull();
    });

    it('returns the too-long message for a value over the max length', () => {
      expect(getFieldError('abcdef', EMPTY_MESSAGE, MAX)).toBe(tooLong(MAX));
    });

    it('compares the trimmed length toward the max length', () => {
      expect(getFieldError('  abc  ', EMPTY_MESSAGE, MAX)).toBeNull();
    });

    it('does not reject internal whitespace or special characters', () => {
      expect(getFieldError('a b!', EMPTY_MESSAGE, MAX)).toBeNull();
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

  describe('isImportStorageConfigValid', () => {
    const validImportConfig = { ...validConfig, exportPrefix: 'my-export' };

    it('returns true when every field including the export prefix passes', () => {
      expect(isImportStorageConfigValid(validImportConfig)).toBe(true);
    });

    it.each([
      ['the export prefix is empty', { ...validImportConfig, exportPrefix: '' }],
      ['the export prefix is missing', validConfig],
      ['the export prefix is whitespace only', { ...validImportConfig, exportPrefix: '   ' }],
      [
        'the export prefix exceeds the length the database allows',
        { ...validImportConfig, exportPrefix: 'a'.repeat(MAX_EXPORT_PREFIX_LENGTH + 1) },
      ],
      ['a shared storage field is invalid', { ...validImportConfig, bucketName: '' }],
    ])('returns false when %s', (_, config) => {
      expect(isImportStorageConfigValid(config)).toBe(false);
    });

    it('accepts an export prefix exactly at the length the database allows', () => {
      const exportPrefix = 'a'.repeat(MAX_EXPORT_PREFIX_LENGTH);

      expect(isImportStorageConfigValid({ ...validImportConfig, exportPrefix })).toBe(true);
    });
  });
});
