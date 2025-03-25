/**
 * Returns storage information for a blob
 *
 * @param {Object} blobInfo - The blob information object
 * @param {boolean} blobInfo.storedExternally - Whether the blob is stored externally
 * @param {string} blobInfo.externalStorage - The type of external storage (e.g., 'lfs')
 * @returns {Object} Storage information object
 * @returns {boolean} returns.isExternallyStored - Whether the blob is stored externally
 * @returns {string} returns.storageType - The type of external storage
 * @returns {boolean} returns.isLfs - Whether the blob is stored in LFS (Large File Storage)
 */
const getStorageInfo = ({ storedExternally, externalStorage }) => ({
  isExternallyStored: storedExternally,
  isLfs: Boolean(storedExternally) && externalStorage === 'lfs',
});

/**
 * Determines whether to show the blame button for a blob
 * The blame button should not be shown for externally stored files or LFS files
 *
 * @param {Object} blobInfo - The blob information object
 * @param {boolean} blobInfo.storedExternally - Whether the blob is stored externally
 * @param {string} blobInfo.externalStorage - The type of external storage (e.g., 'lfs')
 * @returns {boolean} Whether to show the blame button
 */
export const showBlameButton = (blobInfo) => {
  const { isExternallyStored, isLfs } = getStorageInfo(blobInfo);
  return !isExternallyStored && !isLfs;
};

/**
 * Determines whether the blob is using Git LFS (Large File Storage)
 *
 * @param {Object} blobInfo - The blob information object
 * @param {boolean} blobInfo.storedExternally - Whether the blob is stored externally
 * @param {string} blobInfo.externalStorage - The type of external storage (e.g., 'lfs')
 * @returns {boolean} Whether the blob is using LFS
 */
export const isUsingLfs = (blobInfo) => {
  return getStorageInfo(blobInfo).isLfs;
};
