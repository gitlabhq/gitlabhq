import axios from '~/lib/utils/axios_utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';

export const uploadModel = ({
  importPath,
  file,
  subfolder,
  maxAllowedFileSize,
  onUploadProgress,
  cancelToken,
}) => {
  if (!file) {
    return Promise.resolve();
  }

  if (subfolder && subfolder.includes(' ')) {
    return Promise.reject(new Error(s__('MlModelRegistry|Subfolder cannot contain spaces')));
  }

  if (!maxAllowedFileSize) {
    return Promise.resolve(s__('MlModelRegistry|Provide the max allowed file size'));
  }

  if (file.size > maxAllowedFileSize) {
    const errorMessage = sprintf(
      s__(
        'MlModelRegistry|File "%{name}" is %{size}. It is larger than max allowed size of %{maxAllowedFileSize}',
      ),
      {
        name: file.name,
        size: numberToHumanSize(file.size),
        maxAllowedFileSize: numberToHumanSize(maxAllowedFileSize),
      },
    );
    return Promise.reject(new Error(errorMessage));
  }

  const importUrl = joinPaths(importPath, subfolder, encodeURIComponent(file.name));
  return axios.put(importUrl, file, { onUploadProgress, cancelToken });
};
