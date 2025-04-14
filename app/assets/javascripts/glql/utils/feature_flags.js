export const glqlWorkItemsFeatureFlagEnabled = () => {
  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get('glqlWorkItems') === 'false') {
    return false;
  }

  return Boolean(gon.features?.glqlWorkItems);
};
