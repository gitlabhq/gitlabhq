export const hasLatestPipeline = state => !state.isLoadingPipeline && !!state.latestPipeline;

export const failedJobs = state =>
  state.stages.reduce(
    (acc, stage) => acc.concat(stage.jobs.filter(job => job.status === 'failed')),
    [],
  );
