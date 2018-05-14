// eslint-disable-next-line import/prefer-default-export
export const hasLatestPipeline = state => !state.isLoadingPipeline && !!state.latestPipeline;
