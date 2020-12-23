export const findCommitIndex = (commits, commitShortId) => {
  return commits.findIndex((commit) => commit.short_id === commitShortId);
};

export const setCommitStatus = (commits, commitIndex, selected) => {
  const tempCommits = [...commits];
  tempCommits[commitIndex] = {
    ...tempCommits[commitIndex],
    isSelected: selected,
  };
  return tempCommits;
};

export const removeIfReadyToBeRemoved = (toRemoveCommits, commitShortId) => {
  const tempToRemoveCommits = [...toRemoveCommits];
  const isPresentInToRemove = tempToRemoveCommits.indexOf(commitShortId);
  if (isPresentInToRemove !== -1) {
    tempToRemoveCommits.splice(isPresentInToRemove, 1);
  }

  return tempToRemoveCommits;
};

export const removeIfPresent = (selectedCommits, commitShortId) => {
  const tempSelectedCommits = [...selectedCommits];
  const selectedCommitsIndex = findCommitIndex(tempSelectedCommits, commitShortId);
  if (selectedCommitsIndex !== -1) {
    tempSelectedCommits.splice(selectedCommitsIndex, 1);
  }

  return tempSelectedCommits;
};
