import getStateKey from '~/vue_merge_request_widget/stores/get_state_key';
import { DETAILED_MERGE_STATUS, MWCP_MERGE_STRATEGY } from '~/vue_merge_request_widget/constants';

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

  describe('AutoMergeStrategy "merge_when_checks_pass"', () => {
    const createContext = (detailedMergeStatus, preferredAutoMergeStrategy, autoMergeEnabled) => ({
      canMerge: true,
      commitsCount: 2,
      detailedMergeStatus,
      preferredAutoMergeStrategy,
      autoMergeEnabled,
    });

    it.each`
      scenario                   | detailedMergeStatus                   | autoMergeEnabled | state
      ${'MWCP and not approved'} | ${DETAILED_MERGE_STATUS.NOT_APPROVED} | ${false}         | ${'readyToMerge'}
      ${'MWCP and approved'}     | ${DETAILED_MERGE_STATUS.MERGEABLE}    | ${false}         | ${'readyToMerge'}
    `(
      'when $scenario, state should equal $state',
      ({ detailedMergeStatus, autoMergeEnabled, state }) => {
        const bound = getStateKey.bind(
          createContext(detailedMergeStatus, MWCP_MERGE_STRATEGY, autoMergeEnabled),
        );

        expect(bound()).toBe(state);
      },
    );
  });
});
