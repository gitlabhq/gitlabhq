import CodeQualityComparisonWorker from '../../workers/codequality_comparison_worker';

export const parseCodeclimateMetrics = (issues = [], path = '') => {
  return issues.map(issue => {
    const parsedIssue = {
      ...issue,
      name: issue.description,
    };

    if (issue?.location?.path) {
      let parseCodeQualityUrl = `${path}/${issue.location.path}`;
      parsedIssue.path = issue.location.path;

      if (issue?.location?.lines?.begin) {
        parsedIssue.line = issue.location.lines.begin;
        parseCodeQualityUrl += `#L${issue.location.lines.begin}`;
      } else if (issue?.location?.positions?.begin?.line) {
        parsedIssue.line = issue.location.positions.begin.line;
        parseCodeQualityUrl += `#L${issue.location.positions.begin.line}`;
      }

      parsedIssue.urlPath = parseCodeQualityUrl;
    }

    return parsedIssue;
  });
};

export const doCodeClimateComparison = (headIssues, baseIssues) => {
  // Do these comparisons in worker threads to avoid blocking the main thread
  return new Promise((resolve, reject) => {
    const worker = new CodeQualityComparisonWorker();
    worker.addEventListener('message', ({ data }) =>
      data.newIssues && data.resolvedIssues ? resolve(data) : reject(data),
    );
    worker.postMessage({
      headIssues,
      baseIssues,
    });
  });
};
