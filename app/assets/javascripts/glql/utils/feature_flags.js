export const glqlWorkItemsFeatureFlagEnabled = () => {
  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get('glqlWorkItems') === 'false') {
    return false;
  }

  return Boolean(gon.features?.glqlWorkItems);
};

export const glqlTypescriptFeatureFlagEnabled = () => {
  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get('glqlTypescript') === 'false') {
    return false;
  }

  return Boolean(gon.features?.glqlTypescript);
};

export const glqlAggregationEnabled = () => {
  return Boolean(gon.features?.glqlAggregation);
};

export const glqlFeatureFlags = () => ({
  glqlWorkItems: glqlWorkItemsFeatureFlagEnabled(),
  glqlTypescript: glqlTypescriptFeatureFlagEnabled(),
});
