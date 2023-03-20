import { shallowMount } from '@vue/test-utils';
import MergeChecksFailed from '~/vue_merge_request_widget/components/states/merge_checks_failed.vue';
import { DETAILED_MERGE_STATUS } from '~/vue_merge_request_widget/constants';
import BoldText from '~/vue_merge_request_widget/components/bold_text.vue';

let wrapper;

function factory(propsData = {}) {
  wrapper = shallowMount(MergeChecksFailed, {
    propsData,
  });
}

describe('Merge request widget merge checks failed state component', () => {
  it.each`
    mrState                                                                  | displayText
    ${{ approvals: true, isApproved: false }}                                | ${'approvalNeeded'}
    ${{ detailedMergeStatus: DETAILED_MERGE_STATUS.BLOCKED_STATUS }}         | ${'blockingMergeRequests'}
    ${{ detailedMergeStatus: DETAILED_MERGE_STATUS.EXTERNAL_STATUS_CHECKS }} | ${'externalStatusChecksFailed'}
  `('display $displayText text for $mrState', ({ mrState, displayText }) => {
    factory({ mr: mrState });

    const message = wrapper.findComponent(BoldText).props('message');
    expect(message).toContain(MergeChecksFailed.i18n[displayText]);
  });
});
