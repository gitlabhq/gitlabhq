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
      detailedMergeStatus: 'PREPARING',
    };
    const bound = getStateKey.bind(context);

    expect(bound()).toEqual('preparing');

    context.detailedMergeStatus = null;

    expect(bound()).toEqual('checking');

    context.detailedMergeStatus = 'MERGEABLE';

    expect(bound()).toEqual('readyToMerge');

    context.autoMergeEnabled = true;
    context.hasMergeableDiscussionsState = true;

    expect(bound()).toEqual('autoMergeEnabled');

    context.canMerge = true;
    context.isSHAMismatch = true;

    expect(bound()).toEqual('shaMismatch');

    context.canMerge = false;
    context.detailedMergeStatus = 'DISCUSSIONS_NOT_RESOLVED';

    expect(bound()).toEqual('unresolvedDiscussions');

    context.detailedMergeStatus = 'DRAFT_STATUS';

    expect(bound()).toEqual('draft');

    context.detailedMergeStatus = 'CI_MUST_PASS';

    expect(bound()).toEqual('pipelineFailed');

    context.shouldBeRebased = true;

    expect(bound()).toEqual('rebase');

    context.hasConflicts = true;

    expect(bound()).toEqual('conflicts');

    context.detailedMergeStatus = 'CHECKING';

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
