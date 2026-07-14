export const createSubscriptionsCollection = () => {
  const subscriptions = new Map();

  return {
    syncSubscriptions(ids, factory) {
      const desiredSet = new Set(ids);
      for (const [id, unsubscribe] of subscriptions) {
        if (!desiredSet.has(id)) {
          unsubscribe();
          subscriptions.delete(id);
        }
      }
      for (const id of ids) {
        if (!subscriptions.has(id)) {
          const unsubscribe = factory(id);
          subscriptions.set(id, unsubscribe);
        }
      }
    },
    unsubscribeAll() {
      for (const unsubscribe of subscriptions.values()) {
        unsubscribe();
      }
      subscriptions.clear();
    },
  };
};

export const updateDownstreamPipelineInList = (
  pipelines = [],
  { parentGraphqlId, updatedDownstream },
) => {
  const pipelineIndex = pipelines.findIndex((p) => p.graphqlId === parentGraphqlId);
  if (pipelineIndex === -1) return pipelines;

  const pipeline = pipelines[pipelineIndex];
  const downstreamNodes = pipeline.downstream?.nodes || [];
  const downstreamIndex = downstreamNodes.findIndex((d) => d.id === updatedDownstream.id);
  if (downstreamIndex === -1) return pipelines;

  return pipelines.map((p, i) => {
    if (i !== pipelineIndex) return p;
    return {
      ...p,
      downstream: {
        ...p.downstream,
        nodes: downstreamNodes.map((d, j) =>
          j === downstreamIndex ? { ...d, ...updatedDownstream } : d,
        ),
      },
    };
  });
};
