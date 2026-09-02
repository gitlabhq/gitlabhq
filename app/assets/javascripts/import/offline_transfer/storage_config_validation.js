import { s__, sprintf } from '~/locale';
import { safeTrim } from '~/lib/utils/forms';

// https://docs.aws.amazon.com/STS/latest/APIReference/API_Credentials.html
const AWS_MAX_CREDENTIAL_LENGTH = 128;
// https://docs.aws.amazon.com/accounts/latest/APIReference/API_Region.html
const AWS_MAX_REGION_LENGTH = 50;
// https://docs.aws.amazon.com/AmazonS3/latest/userguide/s3-tables-buckets-naming.html#table-buckets-naming-rules
const AWS_MAX_BUCKET_NAME_LENGTH = 63;
// db/migrate/20251028183722_create_import_offline_configurations.rb
const MAX_EXPORT_PREFIX_LENGTH = 255;

const tooLong = (max) => sprintf(s__('OfflineTransfer|Enter %{max} characters or fewer.'), { max });

// returns custom error string for invalid field, or null (valid field)
export const getFieldError = (value, emptyMessage, maximum) => {
  const val = safeTrim(value);
  if (!val) return emptyMessage;
  if (val.length > maximum) return tooLong(maximum);
  return null;
};

const getAccessKeyIdError = (value = '') =>
  getFieldError(value, s__('OfflineTransfer|Enter an access key ID.'), AWS_MAX_CREDENTIAL_LENGTH);

const getSecretAccessKeyError = (value = '') =>
  getFieldError(
    value,
    s__('OfflineTransfer|Enter a secret access key.'),
    AWS_MAX_CREDENTIAL_LENGTH,
  );

const getRegionError = (value = '') =>
  getFieldError(value, s__('OfflineTransfer|Enter a region.'), AWS_MAX_REGION_LENGTH);

const getBucketNameError = (value = '') =>
  getFieldError(value, s__('OfflineTransfer|Enter a bucket name.'), AWS_MAX_BUCKET_NAME_LENGTH);

export const getExportPrefixError = (value = '') =>
  getFieldError(value, s__('OfflineTransfer|Enter an export prefix.'), MAX_EXPORT_PREFIX_LENGTH);

export const getStorageConfigErrors = (config = {}) => ({
  accessKeyId: getAccessKeyIdError(config.accessKeyId),
  secretAccessKey: getSecretAccessKeyError(config.secretAccessKey),
  region: getRegionError(config.region),
  bucketName: getBucketNameError(config.bucketName),
});

export const isStorageConfigValid = (config = {}) =>
  Object.values(getStorageConfigErrors(config)).every((fieldError) => fieldError === null);

/* :offline_imports also requires a prexisting exportPrefix (see lib/api/offline_transfers.rb) which was emailed to the user when the initial export completed (see app/views/notify/offline_export_complete.html.haml)
 */
export const isImportStorageConfigValid = (config = {}) =>
  isStorageConfigValid(config) && getExportPrefixError(config.exportPrefix) === null;
