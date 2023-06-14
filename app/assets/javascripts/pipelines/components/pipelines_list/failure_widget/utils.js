export const isFailedJob = (job = {}) => {
  return job?.detailedStatus?.group === 'failed' || false;
};

export const sortJobsByStatus = (jobs = []) => {
  const newJobs = [...jobs];

  return newJobs.sort((a) => {
    if (isFailedJob(a)) {
      return -1;
    }

    return 1;
  });
};
