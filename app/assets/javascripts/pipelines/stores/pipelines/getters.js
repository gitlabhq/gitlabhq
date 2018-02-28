export const shouldRenderErrorState = state => state.hasError && !state.isLoading;

export const shouldRenderEmptyState = (state) => {
  if (state.viewType === 'main') {
    return !state.isLoading &&
    !state.hasError &&
    !state.pipelines.length &&
    state.scope !== 'all' &&
    state.scope !== null;
  }

  return !state.pipelines.length &&
  !state.isLoading &&
  state.hasMadeRequest &&
  !state.hasError;
};

export const shouldRenderPipelinesTable = state => !state.isLoading &&
  !state.hasError &&
  state.pipelines.length;

export const shouldRenderRunPipelineButton = state => state.permissions.canCreatePipeline && state.hasCI;

export const shouldRenderClearCacheButton = state => state.permissions.