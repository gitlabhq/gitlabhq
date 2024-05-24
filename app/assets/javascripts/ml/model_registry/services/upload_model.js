import axios from '~/lib/utils/axios_utils';
import { contentTypeMultipartFormData } from '~/lib/utils/headers';
import { joinPaths } from '~/lib/utils/url_utility';

export const uploadModel = ({ importPath, file }) => {
  if (!file) {
    return Promise.resolve();
  }

  const formData = new FormData();
  const importUrl = joinPaths(importPath, encodeURIComponent(file.name));

  formData.append('file', file);

  return axios.put(importUrl, formData, {
    headers: {
      ...contentTypeMultipartFormData,
    },
  });
};
