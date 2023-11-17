export const parseCodeclimateMetrics = (issues = [], blobPath = '') => {
  return issues.map((issue) => {
    // the `file_path` attribute from the artifact is returned as `file` by GraphQL
    const issuePath = issue.file_path || issue.path;
    const parsedIssue = {
      name: issue.description,
      path: issuePath,
      urlPath: `${blobPath}/${issuePath}#L${issue.line}`,
      ...issue,
    };

    if (issue?.location?.path) {
      let parseCodeQualityUrl = `${blobPath}/${issue.location.path}`;
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
