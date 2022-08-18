import { shallowMount } from '@vue/test-utils';
import MergeChecksFailed from '~/vue_merge_request_widget/components/states/merge_checks_failed.vue';

let wrapper;

function factory(propsData = {}) {
  wrapper = shallowMount(MergeChecksFailed, {
    propsData,
  });
}

describe('Merge request widget merge checks failed state component', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    mrState                                          | displayText
    ${{ approvals: true, isApproved: false }}        | ${'approvalNeeded'}
    ${{ blockingMergeRequests: { total_count: 1 } }} | ${'blockingMergeRequests'}
  `('display $displayText text for $mrState', ({ mrState, displayText }) => {
    factory({ mr: mrState });

    expect(wrapper.text()).toContain(MergeChecksFailed.i18n[displayText]);
  });
});
