import axios from '~/lib/utils/axios_utils';
import { isReasonableGitUrl } from '~/lib/utils/url_utility';

export async function checkRepositoryConnection(validationPath, { url, user, password }) {
  if (!isReasonableGitUrl(url)) {
    return { isValid: false, success: false, message: null };
  }

  try {
    const { data } = await axios.post(validationPath, {
      url,
      user,
      password,
    });

    return {
      isValid: true,
      success: data.success,
      message: data.message,
    };
  } catch (error) {
    return {
      isValid: true,
      success: false,
      message: error.message,
    };
  }
}
