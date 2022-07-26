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
      projectArchived: false,
      branchMissing: false,
      commitsCount: 2,
      hasConflicts: false,
      draft: false,
    };
    const bound = getStateKey.bind(context);

    expect(bound()).toEqual(null);

    context.canBeMerged = true;

    expect(bound()).toEqual('readyToMerge');

    context.autoMergeEnabled = true;
    context.hasMergeableDiscussionsState = true;

    expect(bound()).toEqual('autoMergeEnabled');

    context.canMerge = true;
    context.isSHAMismatch = true;

    expect(bound()).toEqual('shaMismatch');

    context.canMerge = false;
    context.isPipelineBlocked = true;

    expect(bound()).toEqual('pipelineBlocked');

    context.hasMergeableDiscussionsState = true;
    context.autoMergeEnabled = false;

    expect(bound()).toEqual('unresolvedDiscussions');

    context.draft = true;

    expect(bound()).toEqual('draft');

    context.onlyAllowMergeIfPipelineSucceeds = true;
    context.isPipelineFailed = true;

    expect(bound()).toEqual('pipelineFailed');

    context.shouldBeRebased = true;

    expect(bound()).toEqual('rebase');

    context.hasConflicts = true;

    expect(bound()).toEqual('conflicts');

    context.mergeStatus = 'unchecked';

    expect(bound()).toEqual('checking');

    context.commitsCount = 0;

    expect(bound()).toEqual('nothingToMerge');

    context.commitsCount = 1;
    context.branchMissing = true;

    expect(bound()).toEqual('missingBranch');

    context.projectArchived = true;

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
      projectArchived: false,
      branchMissing: false,
      commitsCount: 2,
      hasConflicts: false,
      draft: false,
    };
    const bound = getStateKey.bind(context);

    expect(bound()).toEqual('rebase');
  });
});
