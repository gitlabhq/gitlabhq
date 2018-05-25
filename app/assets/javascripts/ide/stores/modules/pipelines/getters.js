export const hasLatestPipeline = state => !state.isLoadingPipeline && !!state.latestPipeline;

export const pipelineFailed = state =>
  state.latestPipeline && state.latestPipeline.details.status.text === 'failed';

export const failedStages = state =>
  state.stages.filter(stage => stage.status.text === 'failed').map(stage => ({
    ...stage,
    jobs: stage.jobs.filter(job => job.status.text === 'failed'),
  }));

export const failedJobsCount = state =>
  state.stages.reduce(
    (acc, stage) => acc + stage.jobs.filter(j => j.status.text === 'failed').length,
    0,
  );

export const jobsCount = state => state.stages.reduce((acc, stage) => acc + stage.jobs.length, 0);
