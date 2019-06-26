import { commitItemIconMap } from './constants';

export const getCommitIconMap = file => {
  if (file.deleted) {
    return commitItemIconMap.deleted;
  } else if (file.tempFile && !file.prevPath) {
    return commitItemIconMap.addition;
  }

  return commitItemIconMap.modified;
};

export const createPathWithExt = p => {
  const ext = p.lastIndexOf('.') >= 0 ? p.substring(p.lastIndexOf('.') + 1) : '';

  return `${p.substring(1, p.lastIndexOf('.') + 1 || p.length)}${ext || '.js'}`;
};
