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

    context.detailedMergeStatus = 'MERGEABLE';

    expect(bound()).toEqual('readyToMerge');

    context.canMerge = true;
    context.isSHAMismatch = true;

    expect(bound()).toEqual('shaMismatch');

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
});
