export const parseCodeclimateMetrics = (issues = [], path = '') => {
  return issues.map((issue) => {
    const parsedIssue = {
      name: issue.description,
      path: issue.file_path,
      urlPath: `${path}/${issue.file_path}#L${issue.line}`,
      ...issue,
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
