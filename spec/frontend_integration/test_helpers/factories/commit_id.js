const COMMIT_ID_LENGTH = 40;
const DEFAULT_COMMIT_ID = Array(COMMIT_ID_LENGTH).fill('0').join('');

export const createCommitId = (index = 0) =>
  `${index}${DEFAULT_COMMIT_ID}`.substr(0, COMMIT_ID_LENGTH);

export const createCommitIdGenerator = () => {
  let prevCommitId = 0;

  const next = () => {
    prevCommitId += 1;

    return createCommitId(prevCommitId);
  };

  return {
    next,
  };
};
