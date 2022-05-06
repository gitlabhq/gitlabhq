/*
    We get the failure and failure summary from Rails which has
    a summary failure log. Here we combine that data with the data
    from GraphQL to display the log.

    failedJobs is from GraphQL
    failedJobsSummary is from Rails
  */

export const prepareFailedJobs = (failedJobs = [], failedJobsSummary = []) => {
  const combinedJobs = [];

  if (failedJobs.length > 0 && failedJobsSummary.length > 0) {
    failedJobs.forEach((failedJob) => {
      const foundJob = failedJobsSummary.find(
        (failedJobSummary) => failedJob.normalizedId === failedJobSummary.id,
      );

      if (foundJob) {
        combinedJobs.push({
          ...failedJob,
          failure: foundJob?.failure,
          failureSummary: foundJob?.failure_summary,
          // this field is needed for the slot row-details
          // on the failed_jobs_table.vue component
          _showDetails: true,
        });
      }
    });
  }

  return combinedJobs;
};
