import * as Sentry from '~/sentry/sentry_browser_wrapper';

export const reportToSentry = (component, error) => {
  Sentry.captureException(error, {
    tags: {
      component,
    },
  });
};

export const buildFixPipelineContext = ({ sourceBranch, source, mergeRequestPath } = {}) => {
  return [
    {
      Category: 'merge_request',
      Content: JSON.stringify({
        url: mergeRequestPath || '',
      }),
    },
    {
      Category: 'pipeline',
      Content: JSON.stringify({
        source_branch: sourceBranch || '',
        source: source || '',
      }),
    },
  ];
};
