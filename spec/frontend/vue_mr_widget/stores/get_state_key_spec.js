import getStateKey from '~/vue_merge_request_widget/stores/get_state_key';

describe('getStateKey', () => {
  it('should return proper state name', () => {
    const context = {
      mergeStatus: 'checked',
      autoMergeEnabled: false,
      canMerge: true,
      onlyAllowMergeIfPipelineSucceeds: false,
      isPipelineFailed: false,
      hasMergeableDiscussionsState: false,
      isPipelineBlocked: false,
      canBeMerged: false,
    };
    const data = {
      project_archived: false,
      branch_missing: false,
      commits_count: 2,
      has_conflicts: false,
      work_in_progress: false,
    };
    const bound = getStateKey.bind(context, data);

    expect(bound()).toEqual(null);

    context.canBeMerged = true;

    expect(bound()).toEqual('readyToMerge');

    context.canMerge = false;

    expect(bound()).toEqual('notAllowedToMerge');

    context.autoMergeEnabled = true;

    expect(bound()).toEqual('autoMergeEnabled');

    context.canMerge = true;
    context.isSHAMismatch = true;

    expect(bound()).toEqual('shaMismatch');

    context.canMerge = false;
    context.isPipelineBlocked = true;

    expect(bound()).toEqual('pipelineBlocked');

    context.hasMergeableDiscussionsState = true;

    expect(bound()).toEqual('unresolvedDiscussions');

    context.onlyAllowMergeIfPipelineSucceeds = true;
    context.isPipelineFailed = true;

    expect(bound()).toEqual('pipelineFailed');

    data.work_in_progress = true;

    expect(bound()).toEqual('workInProgress');

    data.has_conflicts = true;

    expect(bound()).toEqual('conflicts');

    context.mergeStatus = 'unchecked';

    expect(bound()).toEqual('checking');

    data.commits_count = 0;

    expect(bound()).toEqual('nothingToMerge');

    data.branch_missing = true;

    expect(bound()).toEqual('missingBranch');

    data.project_archived = true;

    expect(bound()).toEqual('archived');
  });

  it('returns rebased state key', () => {
    const context = {
      mergeStatus: 'checked',
      autoMergeEnabled: false,
      canMerge: true,
      onlyAllowMergeIfPipelineSucceeds: true,
      isPipelineFailed: true,
      hasMergeableDiscussionsState: false,
      isPipelineBlocked: false,
      canBeMerged: false,
      shouldBeRebased: true,
    };
    const data = {
      project_archived: false,
      branch_missing: false,
      commits_count: 2,
      has_conflicts: false,
      work_in_progress: false,
    };
    const bound = getStateKey.bind(context, data);

    expect(bound()).toEqual('rebase');
  });

  it.each`
    canMerge | isSHAMismatch | stateKey
    ${true}  | ${true}       | ${'shaMismatch'}
    ${false} | ${true}       | ${'notAllowedToMerge'}
    ${false} | ${false}      | ${'notAllowedToMerge'}
  `(
    'returns $stateKey when canMerge is $canMerge and isSHAMismatch is $isSHAMismatch',
    ({ canMerge, isSHAMismatch, stateKey }) => {
      const bound = getStateKey.bind(
        {
          canMerge,
          isSHAMismatch,
        },
        {
          commits_count: 2,
        },
      );

      expect(bound()).toEqual(stateKey);
    },
  );
});
