import { commitItemIconMap } from './constants';

export default file => {
  if (file.deleted) {
    return commitItemIconMap.deleted;
  } else if (file.tempFile && !file.prevPath) {
    return commitItemIconMap.addition;
  }

  return commitItemIconMap.modified;
};
