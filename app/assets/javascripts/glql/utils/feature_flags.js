export const glqlCodeSuggestionAnalyticsAggregationEnabled = () => {
  return Boolean(gon.features?.glqlCodeSuggestionAnalyticsAggregation);
};

export const glqlFeatureFlags = () => ({
  glqlWorkItems: true,
  glqlCodeSuggestions: glqlCodeSuggestionAnalyticsAggregationEnabled(),
});
