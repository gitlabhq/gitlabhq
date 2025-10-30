import produce from 'immer';

export const updateSecurityTrainingOptimisticResponse = (changes) => ({
  __typename: 'Mutation',
  securityTrainingUpdate: {
    __typename: 'SecurityTrainingUpdatePayload',
    training: {
      __typename: 'ProjectSecurityTraining',
      ...changes,
    },
    errors: [],
  },
});

export const updateSecurityTrainingCache =
  ({ query, variables }) =>
  (cache, { data }) => {
    const {
      securityTrainingUpdate: { training: updatedProvider },
    } = data;
    const { project } = cache.readQuery({ query, variables });
    if (!updatedProvider.isPrimary) {
      return;
    }

    // when we set a new primary provider, we need to unset the previous one(s)
    const updatedProject = produce(project, (draft) => {
      draft.securityTrainingProviders.forEach((provider) => {
        // eslint-disable-next-line no-param-reassign
        provider.isPrimary = provider.id === updatedProvider.id;
      });
    });

    // write to the cache
    cache.writeQuery({
      query,
      variables,
      data: { project: updatedProject },
    });
  };

export const untrackRefsOptimisticResponse = (refIds) => ({
  __typename: 'Mutation',
  securityTrackedRefsUntrack: {
    __typename: 'SecurityTrackedRefsUntrackPayload',
    untrackedRefIds: refIds,
    errors: [],
  },
});

export const updateUntrackedRefsCache =
  ({ query, variables }) =>
  (cache, { data }) => {
    const {
      securityTrackedRefsUntrack: { untrackedRefIds },
    } = data;

    cache.updateQuery({ query, variables }, (sourceData) =>
      produce(sourceData, (draftData) => {
        if (!draftData?.project?.securityTrackedRefs) {
          return;
        }

        // Remove untracked refs from the list
        draftData.project.securityTrackedRefs = draftData.project.securityTrackedRefs.filter(
          (ref) => !untrackedRefIds.includes(ref.id),
        );
      }),
    );
  };
