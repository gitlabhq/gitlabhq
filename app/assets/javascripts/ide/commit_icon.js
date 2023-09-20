import { commitItemIconMap } from './constants';

export default (file) => {
  if (file.deleted) {
    return commitItemIconMap.deleted;
  }
  if (file.tempFile && !file.prevPath) {
    return commitItemIconMap.addition;
  }

  return commitItemIconMap.modified;
};
