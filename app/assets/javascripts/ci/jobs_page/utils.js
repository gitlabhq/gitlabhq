export const updateJobsNodes = (jobs, ciJobProcessed) => {
  let processedJobDone = false;
  const updatedJobs = jobs.map((job) => {
    if (job.id === ciJobProcessed.id) {
      processedJobDone = true;

      return {
        ...job,
        ...ciJobProcessed,
      };
    }

    return job;
  });

  return {
    updatedJobs,
    processedJobDone,
  };
};
