import axios from '~/lib/utils/axios_utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { contentTypeMultipartFormData } from '~/lib/utils/headers';
import { joinPaths } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';

export const uploadModel = ({
  importPath,
  file,
  subfolder,
  maxAllowedFileSize,
  onUploadProgress,
}) => {
  if (!file) {
    return Promise.resolve();
  }

  if (subfolder && subfolder.includes(' ')) {
    return Promise.reject(new Error(s__('Mlmodelregistry|Subfolder cannot contain spaces')));
  }

  if (!maxAllowedFileSize) {
    return Promise.resolve(s__('Mlmodelregistry|Provide the max allowed file size'));
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

  const formData = new FormData();
  const importUrl = joinPaths(importPath, subfolder, encodeURIComponent(file.name));
  formData.append('file', file);

  return axios.put(importUrl, formData, {
    headers: {
      ...contentTypeMultipartFormData,
    },
    onUploadProgress,
  });
};
