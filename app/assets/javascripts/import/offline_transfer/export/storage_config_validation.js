import { s__, sprintf } from '~/locale';
import { safeTrim } from '~/lib/utils/forms';

// https://docs.aws.amazon.com/STS/latest/APIReference/API_Credentials.html
const AWS_MAX_CREDENTIAL_LENGTH = 128;
// https://docs.aws.amazon.com/accounts/latest/APIReference/API_Region.html
const AWS_MAX_REGION_LENGTH = 50;
// https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-tables-buckets-naming.html#table-buckets-naming-rules
const AWS_MAX_BUCKET_NAME_LENGTH = 63;

const tooLong = (max) =>
  sprintf(s__('OfflineTransferExport|Enter %{max} characters or fewer.'), { max });

export const validateAndCheckLength = (value, emptyMessage, maximum) => {
  const val = safeTrim(value);
  if (!val) return emptyMessage;
  if (val.length > maximum) return tooLong(maximum);
  return null;
};

const validateAccessKeyId = (value = '') =>
  validateAndCheckLength(
    value,
    s__('OfflineTransferExport|Enter an access key ID.'),
    AWS_MAX_CREDENTIAL_LENGTH,
  );

const validateSecretAccessKey = (value = '') =>
  validateAndCheckLength(
    value,
    s__('OfflineTransferExport|Enter a secret access key.'),
    AWS_MAX_CREDENTIAL_LENGTH,
  );

const validateRegion = (value = '') =>
  validateAndCheckLength(
    value,
    s__('OfflineTransferExport|Enter a region.'),
    AWS_MAX_REGION_LENGTH,
  );

const validateBucketName = (value = '') =>
  validateAndCheckLength(
    value,
    s__('OfflineTransferExport|Enter a bucket name.'),
    AWS_MAX_BUCKET_NAME_LENGTH,
  );

export const getStorageConfigErrors = (config = {}) => ({
  accessKeyId: validateAccessKeyId(config.accessKeyId),
  secretAccessKey: validateSecretAccessKey(config.secretAccessKey),
  region: validateRegion(config.region),
  bucketName: validateBucketName(config.bucketName),
});

export const isStorageConfigValid = (config) =>
  Object.values(getStorageConfigErrors(config)).every((error) => error === null);
