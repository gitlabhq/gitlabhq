// eslint-disable-next-line import/prefer-default-export
export const normalizeJob = job => ({
  id: job.id,
  name: job.name,
  status: job.status,
  path: job.build_path,
  rawPath: `${job.build_path}/raw`,
  started: job.started,
  output: '',
  isLoading: false,
});
