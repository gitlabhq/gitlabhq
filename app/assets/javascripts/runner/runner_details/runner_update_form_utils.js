export const runnerToModel = (runner) => {
  const {
    id,
    description,
    maximumTimeout,
    accessLevel,
    active,
    locked,
    runUntagged,
    tagList = [],
  } = runner || {};

  return {
    id,
    description,
    maximumTimeout,
    accessLevel,
    active,
    locked,
    runUntagged,
    tagList: tagList.join(', '),
  };
};

export const modelToUpdateMutationVariables = (model) => {
  const { maximumTimeout, tagList } = model;

  return {
    input: {
      ...model,
      maximumTimeout: maximumTimeout !== '' ? maximumTimeout : null,
      tagList: tagList
        ?.split(',')
        .map((tag) => tag.trim())
        .filter((tag) => Boolean(tag)),
    },
  };
};
