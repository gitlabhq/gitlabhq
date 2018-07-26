import { commitItemIconMap } from './constants';

// eslint-disable-next-line import/prefer-default-export
export const getCommitIconMap = file => {
  if (file.deleted) {
    return commitItemIconMap.deleted;
  } else if (file.tempFile) {
    return commitItemIconMap.addition;
  }

  return commitItemIconMap.modified;
};
