import { buildFixPipelineContext } from '~/ci/utils';

describe('buildFixPipelineContext util', () => {
  it('returns correct context structure', () => {
    const context = buildFixPipelineContext({
      source: 'push',
      sourceBranch: 'duo/fix/2954-fix-check-math-expression',
      mergeRequestPath: 'http://example.com/gitlab-duo/fix-pipeline-flow/-/merge_requests/13',
    });

    expect(context).toEqual([
      {
        Category: 'merge_request',
        Content: JSON.stringify({
          url: 'http://example.com/gitlab-duo/fix-pipeline-flow/-/merge_requests/13',
        }),
      },
      {
        Category: 'pipeline',
        Content: JSON.stringify({
          source_branch: 'duo/fix/2954-fix-check-math-expression',
          source: 'push',
        }),
      },
    ]);
  });

  it('returns empty-string content when called without arguments', () => {
    expect(buildFixPipelineContext()).toEqual([
      {
        Category: 'merge_request',
        Content: JSON.stringify({ url: '' }),
      },
      {
        Category: 'pipeline',
        Content: JSON.stringify({ source_branch: '', source: '' }),
      },
    ]);
  });

  it('coerces null values to empty strings', () => {
    const context = buildFixPipelineContext({
      source: null,
      sourceBranch: null,
      mergeRequestPath: null,
    });

    expect(context).toEqual([
      {
        Category: 'merge_request',
        Content: JSON.stringify({ url: '' }),
      },
      {
        Category: 'pipeline',
        Content: JSON.stringify({ source_branch: '', source: '' }),
      },
    ]);
  });
});
